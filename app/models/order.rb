class Order < ActiveRecord::Base
  extend SpookAndPuff::MoneyAttributes
  attr_money :total, :original_total, :product_total, :original_product_total, :discount, :increase

  include OrderSessionConcern
  include OrderWorkflowConcern
  include OrderPurchasingConcern
  include OrderAdjustmentConcern
  include OrderPromotionConcern

  include PgSearch
  multisearchable :against => [
    :name, :shipping_name, :reference, :email, :billing_city, :billing_postcode,
    :shipping_city, :shipping_postcode
  ]

  # Turn off single table inheritance
  self.inheritance_column = :_type_disabled
  self.table_name = 'orders'

  # A class attribute used to store a reference to the shipping calculator
  # class. This can be over-ridden per install using extensions.
  #
  # The class should at least have an instance method #calculate, which accepts
  # an instance of an order and returns an Integer.
  class_attribute :shipping_calculator
  self.shipping_calculator = :default_shipping_calculator

  # A class attribute used to store a reference to the shipment tracking
  # class. This can be over-ridden per install using extensions.
  #
  # The class should at least have an instance method #track, which accepts
  # an instance of an order and returns an Integer.
  class_attribute :shipment_tracker
  self.shipment_tracker = :default_shipment_tracker

  belongs_to  :person
  has_one     :payment,       :class_name => 'OrderPayment'
  has_many    :logs,          :class_name => 'OrderLog'
  has_many    :items,         :class_name => 'OrderItem'
  has_many    :sku_items,     :class_name => 'OrderSkuItem',      :extend => [OrderItem::SkuPurchasing, OrderItem::Adjustments]
  has_many    :service_items, :class_name => 'OrderServiceItem',  :extend => [OrderItem::ServicePurchasing, OrderItem::Adjustments]

  # Adjustments for order-level increases or discounts.
  has_many :adjustments, :class_name => "OrderAdjustment", :dependent => :destroy, :autosave => true do
    # Returns the first — possibly only — manual adjustment.
    #
    # @return [OrderAdjustment, nil]
    def manual
      select {|a| a.source == 'manual'}.first
    end
  end

  # The workflow is defined here so it can be queried against this class and
  # it's sub-classes, but the actual workflow should be run against an instance
  # of OrderProcess
  workflow(:status, :open) do
    event :add,   {:open     => :pending},  :process_add!
    event :bill,  {:pending  => :billed},   :process_billing!
    event :pack,  {:billed   => :packed}
    event :ship,  {:packed   => :complete}, :process_shipping!

    event :cancel, {[:pending, :billed, :packed] => :cancelled}, :process_cancellation!
  end

  accepts_nested_attributes_for :items
  track_user_edits
  validations_from_schema :except => [:reference]

  # Require shipping address if the user wants to use it.
  validates :shipping_street,    :presence => true, :if => :use_shipping_address?
  validates :shipping_city,      :presence => true, :if => :use_shipping_address?
  validates :shipping_state,     :presence => true, :if => :use_shipping_address?
  validates :shipping_postcode,  :presence => true, :if => :use_shipping_address?

  # Validate email format
  validates :email, :format   => {:with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, :message => 'Please check your email address is correct'}

  # Generates the human readable order ID.
  before_create :store_reference

  # Generates a scope which adds a summary of order items to each row. It is a
  # string consisting of the product name and quantity.
  #
  # @return ActiveRecord::Relation
  def self.items_summary
    select(%{
      orders.*,
      (SELECT ARRAY_TO_STRING(ARRAY_AGG(ps.name::text || ' - ' || skus.short_desc || ' (' || ois.quantity::text || ')'), ', ')
       FROM order_items AS ois
       JOIN skus ON skus.id = ois.sku_id
       JOIN products AS ps ON ps.id = skus.product_id
       GROUP BY order_id HAVING order_id = orders.id) AS items_summary
    })
  end

  # Used to track any items that have gone out of stock.
  #
  # @return Array<Sku>
  def stock_alerts
    @stock_alerts ||= []
  end

  # Indicates if there are any stock alerts for this order. These will generally
  # be generated when loading the order from a JSON dump.
  #
  # @return [true, false]
  def stock_alerts?
    !stock_alerts.empty?
  end

  # Clears out any existing stock alerts.
  #
  # @return nil
  def destroy_alerts
    stock_alerts.clear
    nil
  end

  # Checks to see if there is anything in the order at all.
  #
  # @return [true, false]
  def empty?
    sku_items.empty?
  end

  # Indicates if the order is editable at all. This could mean only partially
  # editable.
  def editable?
    status != 'complete' and status != 'cancelled'
  end

  # Specifies the values that can be safely exposed to the public. This is used
  # by the #dump method to create a JSON string that can be written to session.
  dump_config(
    :methods => [:items_dump, :stock_alerts_dump],
    :properties => [
      :person_id, :name, :phone, :email, :is_gift, :shipping_name, :gift_message,
      :billing_company, :billing_street, :billing_city, :billing_state, :billing_postcode, :billing_country,
      :shipping_company, :shipping_street, :shipping_city, :shipping_state, :shipping_postcode, :shipping_country,
      :shipping_instructions, :use_shipping_address, :use_billing_address, :items_dump, :stock_alerts_dump
    ]
  )

  # Provides an array of SKU ids which are in the order, but have gone out of
  # stock. Used when dumping a JSON representation of the order.
  #
  # @return Array<Integer>
  def stock_alerts_dump
    stock_alerts.map(&:id)
  end

  # Generates stock alerts from previous ones that have been dumped to JSON.
  #
  # @param [Array<Integer>] items ids of SKUs
  # @return Array<Sku>
  def stock_alerts_dump=(items)
    @stock_alerts = if items.empty?
      []
    else
      Sku.where(:id => items)
    end
  end

  # A reversed version of 'use_shipping_address' - returns true if the
  # order is not using a separate shipping address.
  #
  # @return [true, false]
  def use_billing_address?
    !use_shipping_address
  end

  def use_billing_address
    !use_shipping_address
  end

  # Set the use_shipping_address flag to be the reverse of the incoming switch.
  # Parse the switch value from an incoming form param (a string)
  #
  # @param [String] from params, either '0' or '1'
  # @return [true, false]
  def use_billing_address=(switch)
    self.use_shipping_address = !(switch.to_i == 1)
  end

  # Determines the shipping name depending on if it is going to the billing
  # or shipping address and if a shipping name is provided
  #
  # @return String
  def ship_to
    if use_shipping_address? and !shipping_name.blank?
      shipping_name
    else
      name
    end
  end

  # An accessor which falls back to billing details
  #
  # @return String
  def shipping_company
    use_shipping_address? ? self[:shipping_company] : self[:billing_company]
  end

  # An accessor which falls back to billing details
  #
  # @return String
  def shipping_street
    use_shipping_address? ? self[:shipping_street] : self[:billing_street]
  end

  # An accessor which falls back to billing details
  #
  # @return String
  def shipping_city
    use_shipping_address? ? self[:shipping_city] : self[:billing_city]
  end

  # An accessor which falls back to billing details
  #
  # @return String
  def shipping_state
    use_shipping_address? ? self[:shipping_state] : self[:billing_state]
  end

  # An accessor which falls back to billing details
  #
  # @return String
  def shipping_postcode
    use_shipping_address? ? self[:shipping_postcode] : self[:billing_postcode]
  end

  # An accessor which falls back to billing details
  #
  # @return String
  def shipping_country
    use_shipping_address? ? self[:shipping_country] : self[:billing_country]
  end

  # Counts the number of individual SKUs in an order.
  #
  # @return Integer
  def sku_total_quantity
    # sku_items.sku_total_quantity
    0
  end

  # The unit count of the SKUs in an order.
  #
  # @return Integer
  def sku_unit_quantity
    sku_items.reduce(0) do |a, item|
      a + (item.quantity * item.sku.unit_count)
    end
  end

  # Counts the number of a given SKU in an order.
  #
  # @param Sku
  #
  # @return Integer
  def quantity_of_sku(sku)
    sku_items.find_item(sku) ? sku_items.find_item(sku).quantity : 0
  end

  # Indicates if the order has any kind of discount applied to it.
  #
  # @return Boolean
  # @todo: Actually implement this
  def discounted?
    discounted_total?
  end

  # Indicates if any of the products have had a discount applied to them.
  #
  # @return Boolean
  def discounted_products?
    original_product_total > product_total
  end

  # Indicates if any of the products have had a discount applied to them.
  #
  # @return Boolean
  def discounted_shipping?
    original_shipping_total > shipping_total
  end

  # The total discount applied to the products in an order.
  #
  # @return SpookAndPuff::Money
  def product_discount
    original_product_total - product_total
  end

  alias :formatted_product_discount :product_discount

  # Indicates if the order has had a discount of any kind applied to it.
  #
  # @return [true, false]
  def discounted_total?
    original_total > total
  end

  # The discount applied to the entire order.
  #
  # @return SpookAndPuff::Money
  # @todo Deprecate, then remove this.
  def total_discount
    discount
  end

  # The original total for all the paid-for products in the order
  #
  # @return SpookAndPuff::Money
  def paid_original_product_total
    sku_items.paid_total
  end

  alias :formatted_total_discount :total_discount

  # Indicates if the order has free shipping. This is true if there is no
  # shipping service — e.g. no possible charge — or the pre-discount total is
  # zero.
  #
  # @return [true, false]
  def free_shipping?
    shipping_service.nil? or shipping_service.total.zero?
  end

  # This bit of meta-programming generates accessors with a deprecation warning.
  # It is intended to replace the #formatted_* methods on this class.
  #
  # @todo Remove these deprecated methods.
  [:product_total, :original_product_total, :total, :original_total].each do |m|
    class_eval %{
      def formatted_#{m}
        ActiveSupport::Deprecation.warn("#formatted_#{m} is deprecated, use ##{m}.to_s instead.")
        #{m}
      end
    }
  end

  # Tracks the order with the tracker class's track method
  #
  # @return [String, nil]
  def track_shipment
    self.class.shipment_tracker_class.new.track(self)
  end

  # Is the order in a state that can be tracked? (Usually after the order is ready for shipping)
  #
  # @return [Boolean]
  def trackable?
    ['packed', 'shipped', 'complete'].include? status
  end

  # Returns the shipping service attached to this order.
  #
  # @return OrderServiceItem
  def shipping_service
    @shipping_service ||= service_items.select {|i| i.service.key == 'shipping'}.first
  end

  # Returns the shipping total before any adjustments.
  #
  # @return SpookAndPuff::Money
  def original_shipping_total
    shipping_service.pre_discount_total
  end

  # Returns the shipping total.
  #
  # @return SpookAndPuff::Money
  def shipping_total
    shipping_service ? shipping_service.total : SpookAndPuff::Money.zero
  end

  # @todo: Deprecate and remove this later.
  alias :formatted_shipping_total :shipping_total
  alias :formatted_original_shipping_total :original_shipping_total

  # Calculate the shipping, product and order totals. This includes both the
  # original and potentially discounted totals.
  #
  # @return nil
  def calculate_totals
    # Calculate shipping and add it to the order, without retriggering a
    # recalculation of the total.
    shipping = self.class.shipping_calculator_class.new.calculate(self)
    set_quantity_and_price(Service.shipping_service, 1, shipping, :retotal => false)

    # Calculate the totals
    self.product_total          = sku_items.total
    self.original_product_total = sku_items.pre_discount_total
    self.total                  = (product_total + service_items.total).round
    self.original_total         = (original_product_total + service_items.pre_discount_total).round

    # Determine if there has been an increase or a discount on the order and
    # set the appropriate attributes.
    adjustment = self.original_total - self.total
    zero = SpookAndPuff::Money.new("0")

    if adjustment.negative?
      self.increase = adjustment.abs
      self.discount = zero
    else
      self.increase = zero
      self.discount = adjustment
    end
  end

  private

  # Attempts to generate a reference for the order. Since the reference needs to
  # be unique and is generated rather than being a serial value, we attempt to
  # generate it five times. On failure, we raise an error.
  #
  # @return String
  def store_reference
    5.times do
      self[:reference] = generate_reference
      return reference unless self.class.where(:reference => reference).first
    end

    raise "Could not generate unique reference for order"
  end

  # Generates a reference using the time, and a 6 char hex string.
  #
  # @return String
  def generate_reference
    "#{Time.now.strftime('%y%m')}-#{SecureRandom.hex(3).upcase}"
  end

  # Returns the configured shipping calculator class.
  #
  # @return Object
  def self.shipping_calculator_class
    @@shipping_calculator ||= self.shipping_calculator.to_s.classify.constantize
  end

  # Returns the configured shippment tracker class.
  #
  # @return Object
  def self.shipment_tracker_class
    @@shipment_tracker ||= self.shipment_tracker.to_s.classify.constantize
  end

  check_for_extensions
end
