class Order < ActiveRecord::Base
  include IslayShop::OrderWorkflow
  include Islay::Searchable

  search_terms :against => {
    :name => 'A',
    :gifted_to => 'A',
    :reference => 'A',
    :tracking_reference => 'B',
    :email => 'B',
    :phone => 'B',
    :billing_street => 'C',
    :billing_city => 'C',
    :billing_postcode => 'C',
    :shipping_street => 'C',
    :shipping_city => 'C',
    :shipping_postcode => 'C'
  }

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
  has_one     :credit_card_payment
  has_many    :logs, :class_name => 'OrderLog'

  # This association has an extra method attached to it. This is so we can
  # easily retrieve an item by it's sku_id, which is necessary for both
  # #add_item and #remove_item.
  #
  # It is implemented so it can handle the case the there items are in memory
  # only, or where they are persisted in the DB.
  has_many :items, :class_name => 'OrderItem' do
    # Tries to find an existing item in the order by sku_id
    #
    # @param [String, Integer] sku_id
    #
    # @return [OrderItem, nil]
    def by_sku_id(sku_id)
      id = sku_id.to_i

      # We check for existance like this, since this catches records that have
      # both been loaded from the DB and new instances built on the assocation.
      if self[0]
        select {|i| i.sku_id == id}.first
      else
        where(:sku_id => sku_id).first
      end
    end

    # Either finds an existing item with the sku_id, or creates a new instance.
    #
    # @param [String, Integer] sku_id
    #
    # @return OrderItem
    def find_or_initialize(sku_id)
      by_sku_id(sku_id) || build(:sku_id => sku_id)
    end
  end

  # These are the only attributes that we want to expose publically.
  attr_accessible(
    :billing_country, :billing_postcode, :billing_state, :billing_street,
    :billing_city, :email, :gift_message, :gifted_to, :is_gift, :name, :phone,
    :shipping_city, :shipping_country, :shipping_instructions, :shipping_postcode,
    :shipping_state, :shipping_street, :use_shipping_address, :use_billing_address,
    :items_dump, :stock_alerts_dump, :person_id, :reference, :tracking_reference
  )

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
  before_save :calculate_totals
  track_user_edits

  validations_from_schema :except => [:reference, :shipping_total, :original_shipping_total]

  # Require shipping address if the user wants to use it.
  validates :shipping_street,    :presence => true, :if => :use_shipping_address?
  validates :shipping_city,      :presence => true, :if => :use_shipping_address?
  validates :shipping_state,     :presence => true, :if => :use_shipping_address?
  validates :shipping_postcode,  :presence => true, :if => :use_shipping_address?

  # Require recipient and message for gifts
  validates :gifted_to,     :presence => true, :if => :is_gift?
  validates :gift_message,  :presence => true, :if => :is_gift?

  # Validate email format
  validates :email, :format   => {:with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => 'Please check your email address is correct'}

  # Make sure the CC is also valid.
  validates_associated :credit_card_payment

  after_initialize :initialize_totals

  # This callback is used to initialize any totals for this order. Will only
  # run for new records.
  #
  # @return nil
  def initialize_totals
    calculate_totals if new_record?
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
  # @return [Boolean]
  def stock_alerts?
    !stock_alerts.empty?
  end

  # Clears out any existing stock alerts
  def destroy_alerts
    stock_alerts.clear
  end

  # Checks to see if there is anything in the order at all.
  #
  # @return Boolean
  def empty?
    items.empty?
  end

  # Indicates if the order is editable at all. This could mean only partially
  # editable.
  def editable?
    status != 'complete' and status != 'cancelled'
  end

  # Generates and order from a JSON object. The apply boolean indicates if
  # promotions should be applied to the order after it has been loaded.
  #
  # @param [String] json JSON representation of order (result of #dump)
  # @param [Boolean] apply apply promotions after loading
  #
  # @return [Order]
  #
  # @todo Investigate checking stock levels when loading to see if it has
  # been decremented by another action between requests.
  def self.load(json, apply = true)
    order = new(JSON.parse(json))

    # Check stock levels for each regular_item, replacing each with an alert
    # where they are out of stock.
    order.check_stock_levels

    # Conditionally apply the promotions (which will mutate the order)
    order.apply_promotions if apply
    order
  end

  # Specifies the values that can be safely exposed to the public. This is used
  # by the #dump method to create a JSON string that can be written to session.
  DUMP_OPTS = {
    root: false,
    :methods => [:items_dump, :stock_alerts_dump],
    :only => [
      :person_id, :name, :phone, :email, :is_gift, :gifted_to, :gift_message,
      :billing_street, :billing_city, :billing_state, :billing_postcode, :billing_country,
      :shipping_street, :shipping_city, :shipping_state, :shipping_postcode, :shipping_country,
      :shipping_instructions, :use_shipping_address, :items_dump, :stock_alerts_dump
    ]
  }

  # Generates a JSON string representation of the order and it's items. It
  # only dumps the regular items and their quantities. Bonus and discount
  # details are ignored, since they are reapplied when the order is loaded.
  #
  # @return [String] JSON representation of order
  def dump
    to_json(DUMP_OPTS)
  end

  # Provides a simplified representation of the items in an order, consolidating
  # regular and discounted items into a single collection.
  #
  # It is intended to be used when dumping the order contents to JSON.
  #
  # @return [String] JSON representation of order items
  def items_dump
    items.map {|item| {:sku_id => item.sku_id, :quantity => item.quantity}}
  end

  # When loading up an order from session, this accessor is used to generate the
  # regular item instances on the order model.
  #
  # @param [Array<Hash>] items raw values for order items
  def items_dump=(items)
    items.each {|i| self.items.build(i).valid? }
  end

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
  # @return Boolean
  def use_billing_address?
    !use_shipping_address
  end

  def use_billing_address
    !use_shipping_address
  end

  def use_billing_address=(switch)
    use_shipping_address = !switch
  end


  # Determines the shipping name depending on if it is going to the billing
  # or shipping address and if it is a gift.
  #
  # @return String
  def ship_to
    if use_shipping_address? and is_gift?
      gifted_to
    else
      name
    end
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
    items.sku_total_quantity
  end

  # Indicates if the order has any kind of discount applied to it.
  #
  # @return Boolean
  # @todo: Actually implement this
  def discounted?
    false
  end

  # Indicates if any of the products have had a discount applied to them.
  #
  # @return Boolean
  def discounted_products?
    original_product_total > product_total
  end

  # The total discount applied to the products in an order.
  #
  # @return Float
  def product_discount
    original_product_total - product_total
  end

  # Discount formatted to a money string
  #
  # @return String
  def formatted_product_discount
    format_money(product_discount)
  end

  # Indicates if the order has had a discount of any kind applied to it.
  #
  # @return Boolean
  def discounted_total?
    original_total > total
  end

  # The discount applied to the entire order.
  def total_discount
    original_total - total
  end

  # Discount formatted to a money string
  #
  # @return String
  def formatted_total_discount
    format_money(total_discount)
  end

  # Indicates if the order has free shipping.
  #
  # @return Boolean
  def free_shipping?
    shipping_total < 1
  end

  # Returns a formatted string of the order total.
  #
  # @return String
  def formatted_total
    self[:formatted_total] || format_money(total)
  end

  # Returns a formatted string of the order product total.
  #
  # @return String
  def formatted_product_total
    format_money(product_total)
  end

  # Returns a formatted string of the order shipping total.
  #
  # @return [String, nil]
  def formatted_shipping_total
    if shipping_total != nil
      if shipping_total == 0
        'Free'
      elsif shipping_total > 0
        format_money(shipping_total)
      end
    end
  end

  # Formats a float into a monentary formatted string i.e. sticks a '$' in the
  # front and pads the decimals.
  #
  # @param Float value
  #
  # @return String
  def format_money(value)
    "$%.2f" % value
  end

  # Iterates over the regular_items in the order, checking each to see if they
  # are in stock. Where they are out of stock, the item is removed and we add a
  # stock alert for that item to the order.
  def check_stock_levels
    items.each do |item|
      if item.sku.out_of_stock?
        stock_alerts << item.sku
        items.delete(item)
      end
    end
  end

  class PromotionApplyError < StandardError
    def to_s
      "This order has promotions applied to it. You cannot modify it without
       removing them first. Try calling #remove_promotions on the order first."
    end
  end

  def remove_promotions
    bonus_items.delete

    discount_items.each do |item|
      regular_items.build(:sku_id => item.sku_id, :quantity => item.quantity)
      discount_items.delete(item)
    end

    @_promotions_applied = false
  end

  def apply_promotions
    raise PromotionApplyError if @_promotions_applied

    Promotion.active.each {|p| p.apply!(self) if p.qualifies?(self)}
    @_promotions_applied = true
  end

  # Calculates the shipping for the order.
  #
  # @return [Float, nil]
  def calculate_shipping
    self.class.shipping_calculator_class.new.calculate(self)
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

  private

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

  # Calculate the shipping, product and order totals. This includes both the
  # original and potentially discounted totals.
  #
  # @return nil
  def calculate_totals
    self.shipping_total = self.original_shipping_total = calculate_shipping

    self.original_product_total = items.map(&:original_total).sum
    self.product_total = items.map(&:total).sum

    self.original_total = if original_shipping_total
      original_product_total + original_shipping_total
    else
      original_product_total
    end

    self.total = if shipping_total
      product_total + shipping_total
    else
      product_total
    end

    nil
  end

  check_for_extensions
end
