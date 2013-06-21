class Order < ActiveRecord::Base
  include IslayShop::OrderWorkflow
  include IslayShop::OrderSession
  include IslayShop::OrderPromotions
  include Islay::Searchable

  search_terms :against => {
    :name => 'A',
    :shipping_name => 'A',
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
    :billing_company, :billing_country, :billing_postcode, :billing_state, :billing_street,
    :billing_city, :email, :gift_message, :is_gift, :name, :phone,
    :shipping_name, :shipping_company, :shipping_city, :shipping_country, :shipping_instructions,
    :shipping_postcode, :shipping_state, :shipping_street, :use_shipping_address, :use_billing_address,
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
  track_user_edits

  validations_from_schema :except => [:reference, :shipping_total, :original_shipping_total]

  # Require shipping address if the user wants to use it.
  validates :shipping_street,    :presence => true, :if => :use_shipping_address?
  validates :shipping_city,      :presence => true, :if => :use_shipping_address?
  validates :shipping_state,     :presence => true, :if => :use_shipping_address?
  validates :shipping_postcode,  :presence => true, :if => :use_shipping_address?

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

  # Set the use_shipping_address flag to be the reverse of the incoming switch.
  # Parse the switch value from an incoming form param (a string)
  #
  # @param [String] from params, either '0' or '1'
  #
  # @return Boolean
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
    items.sku_total_quantity
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


  # Returns a formatted string of the original (pre-discount) grand total.
  #
  # @return String
  def formatted_original_total
    format_money(original_total)
  end

  # Returns a formatted string of the order product total.
  #
  # @return String
  def formatted_product_total
    format_money(product_total)
  end

  # Returns a formatted string of the original (pre-discount) product total.
  #
  # @return String
  def formatted_original_product_total
    format_money(original_product_total)
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

  # Returns a formatted string of the original shipping total.
  #
  # @return [String, nil]
  def formatted_original_shipping_total
    if original_shipping_total != nil
      if original_shipping_total == 0
        'Free'
      elsif original_shipping_total > 0
        format_money(original_shipping_total)
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
    self.original_shipping_total = calculate_shipping
    self.shipping_total ||= self.original_shipping_total

    self.original_product_total = items.map(&:original_total).sum
    self.product_total ||= items.map(&:total).sum

    self.original_total = (original_product_total || 0) + (original_shipping_total || 0)
    self.total = (product_total || 0) + (shipping_total || 0)
        
    self.discount = (self.original_total - self.total).round(2)

    nil
  end

  check_for_extensions
end
