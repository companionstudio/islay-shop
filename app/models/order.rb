class Order < ActiveRecord::Base
  include IslayShop::OrderWorkflow

  # Turn off single table inheritance
  self.inheritance_column = :_type_disabled
  self.table_name = 'orders'

  belongs_to  :person
  has_one     :credit_card_payment
  has_one     :spreedly_core_payment
  has_many    :items,            :class_name => 'OrderItem'
  has_many    :bonus_items,      :class_name => 'OrderBonusItem'
  has_many    :discount_items,   :class_name => 'OrderDiscountItem'
  has_many    :logs,             :class_name => 'OrderLog'

  # These are the only attributes that we want to expose publically.
  attr_accessible(
    :billing_country, :billing_postcode, :billing_state, :billing_street,
    :billing_city, :email, :gift_message, :gifted_to, :is_gift, :name, :phone,
    :shipping_city, :shipping_country, :shipping_instructions, :shipping_postcode,
    :shipping_state, :shipping_street, :use_shipping_address, :items_dump,
    :stock_alerts_dump
  )

  # The workflow is defined here so it can be queried against this class and
  # it's sub-classes, but the actual workflow should be run against an instance
  # of OrderProcess
  workflow(:status, :open) do
    event :add,   {:open     => :pending}
    event :bill,  {:pending  => :billed}
    event :pack,  {:billed   => :packed}
    event :ship,  {:packed   => :complete}

    event :cancel, {[:pending, :billed, :packed] => :cancelled}
  end

  # This association has an extra method attached to it. This is so we can
  # easily retrieve an item by it's sku_id, which is necessary for both
  # #add_item and #remove_item.
  #
  # It is implemented so it can handle the case the there items are in memory
  # only, or where they are persisted in the DB.
  has_many :regular_items, :class_name => 'OrderRegularItem' do
    def by_sku_id(sku_id)
      # We check for existance like this, since this catches records that have
      # both been loaded from the DB and new instances built on the assocation.
      if self[0]
        select {|i| i.sku_id == sku_id}.first
      else
        where(:sku_id => sku_id).first
      end
    end
  end

  accepts_nested_attributes_for :regular_items
  before_save :calculate_totals
  track_user_edits

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
    regular_items.empty?
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
    root: false, :methods => [:items_dump, :stock_alerts_dump],
    :except => [
      :id, :product_total, :shipping_total, :total, :currency, :stock_alerts,
      :creator_id, :updater_id, :created_at, :updated_at, :person_id
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

  # This either returns the stored product total or it calculates it by summing
  # the totals from each regular and discounted line item.
  #
  # @return [Integer] total value of 'purchasable' items in order
  def product_total
    self[:product_total] ||= (regular_items.map(&:total) + discount_items.map(&:total)).sum
  end

  # Provides a simplified representation of the items in an order, consolidating
  # regular and discounted items into a single collection.
  #
  # It is intended to be used when dumping the order contents to JSON.
  #
  # @return [String] JSON representation of order items
  def items_dump
    regular   = regular_items.map   {|item| {:sku_id => item.sku_id, :quantity => item.quantity}}
    discount  = discount_items.map  {|item| {:sku_id => item.sku_id, :quantity => item.quantity}}

    regular + discount
  end

  # When loading up an order from session, this accessor is used to generate the
  # regular item instances on the order model.
  #
  # @param [Array<Hash>] items raw values for order items
  def items_dump=(items)
    items.each {|i| regular_items.build(i)}
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

  # An accessor which falls back to billing details
  #
  # @return String
  def shipping_street
    self[:shipping_street] || self[:billing_street]
  end

  # An accessor which falls back to billing details
  #
  # @return String
  def shipping_city
    self[:shipping_city] || self[:billing_city]
  end

  # An accessor which falls back to billing details
  #
  # @return String
  def shipping_state
    self[:shipping_state] || self[:billing_state]
  end

  # An accessor which falls back to billing details
  #
  # @return String
  def shipping_postcode
    self[:shipping_postcode] || self[:billing_postcode]
  end

  # Counts the number of individual SKUs in an order.
  #
  # @return Integer
  def sku_total_quantity
    items.sku_total_quantity
  end

  # TODO: This should be a stored field
  def reference
    "1203-HGAS"
  end

  # Indicates if the order has any kind of discount applied to it.
  #
  # @return Boolean
  # @todo: Actually implement this
  def discounted?
    false
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
    format_money(total)
  end

  # Returns a formatted string of the order product total.
  #
  # @return String
  def formatted_product_total
    format_money(product_total)
  end

  # Returns a formatted string of the order shipping total.
  #
  # @return String
  def formatted_shipping_total
    format_money(shipping_total)
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
    regular_items.each do |item|
      if item.sku.out_of_stock?
        stock_alerts << item.sku
        regular_items.delete(item)
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

  def calculate_totals
    self.total = product_total + shipping_total
  end
end
