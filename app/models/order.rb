class Order < ActiveRecord::Base
  # Turn off single table inheritance
  self.inheritance_column = :_type_disabled
  self.table_name = 'orders'

  belongs_to  :person
  has_one     :credit_card_payment
  has_many    :items,            :class_name => 'OrderItem'
  has_many    :bonus_items,      :class_name => 'OrderBonusItem'
  has_many    :discount_items,   :class_name => 'OrderDiscountItem'

  # These are the only attributes that we want to expose publically.
  attr_accessible(
    :billing_country, :billing_postcode, :billing_state, :billing_street,
    :billing_city, :email, :gift_message, :gifted_to, :is_gift, :name, :phone,
    :shipping_city, :shipping_country, :shipping_instructions, :shipping_postcode,
    :shipping_state, :shipping_street, :use_shipping_address, :items_dump
  )

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

  # Generates and order from a JSON object. The apply boolean indicates if
  # promotions should be applied to the order after it has been loaded.
  #
  # TODO: Investigate checking stock levels when loading to see if it has
  # been decremented by another action between requests.
  def self.load(json, apply = true)
    order = Order.new(JSON.parse(json))
    order.apply_promotions if apply
    order
  end

  DUMP_OPTS = {
    root: false, :methods => :items_dump,
    :except => [
      :id, :product_total, :shipping_total, :total, :currency,
      :creator_id, :updater_id, :created_at, :updated_at, :person_id
    ]
  }

  # Generates a JSON string representation of the order and it's items. It
  # only dumps the regular items and their quantities. Bonus and discount
  # details are ignored, since they are reapplied when the order is loaded.
  def dump
    to_json(DUMP_OPTS)
  end

  # Loads an order from a JSON object. Adds the item specified, then applies
  # promotions, returning the order instance
  def self.load_and_add_item(json, sku_id, quantity)
    order = load(json, false)
    order.add_or_update_item(sku_id, quantity)
    order.apply_promotions

    order
  end

  # Loads an order from a JSON object. removes the item specified, then applies
  # promotions, returning the order instance
  def self.load_and_remove_item(json, sku_id)
    order = load(json, false)
    order.remove_item(sku_id)
    order.apply_promotions

    order
  end

  # Adds or updates an item based on the sku_id. If the item exists, it's
  # quantity is incremented by the specified amount, otherwise a new item is
  # created.
  #
  # TODO: This action needs to account for and handle exhausted stock levels.
  def add_or_update_item(sku_id, quantity, mode = :add)
    sku_id    = sku_id.to_i
    quantity  = quantity.to_i

    item = regular_items.by_sku_id(sku_id) || regular_items.build(:sku_id => sku_id)
    item.quantity = if item.quantity.blank?
      quantity
    else
      case mode
      when :add     then item.quantity + quantity
      when :update  then quantity
      end
    end
  end

  # This is a shortcut for updating multiple items in one go. It replaces any
  # existing item quantities with the passed in values.
  def update_items(items)
    items.each {|k, i| add_or_update_item(i[:sku_id], i[:quantity], :update)}
  end

  # Removes the a regular item specified by it's sku_id.
  def remove_item(sku_id)
    regular_items.delete(regular_items.by_sku_id(sku_id))
  end

  # Apply a discount to a regular item by replacing it with an instance of a
  # discount_item.
  def discount_item(sku_id, discount_price, discount_percentage)
    item = regular_items.by_sku_id(sku_id)
    discount_items.build(
      :sku_id   => sku_id,
      :quantity => item.quantity,
      :price    => discount_price,
      :discount => discount_percentage
    )
    regular_items.delete(item)
  end

  # Does what it says on the tin.
  def add_bonus_item(sku_id, quantity)
    bonus_items.build(:sku_id => sku_id, :quantity => quantity)
  end

  # This either returns the stored product total or it calculates it by summing
  # the totals from each regular and discounted line item.
  def product_total
    self[:product_total] ||= (regular_items.map(&:total) + discount_items.map(&:total)).sum
  end

  # Provides a simplified representation of the items in an order, consolidating
  # regular and discounted items into a single collection.
  #
  # It is intended to be used when dumping the order contents to JSON.
  def items_dump
    regular   = regular_items.map   {|item| {:sku_id => item.sku_id, :quantity => item.quantity}}
    discount  = discount_items.map  {|item| {:sku_id => item.sku_id, :quantity => item.quantity}}

    regular + discount
  end

  # When loading up an order from session, this accessor is used to generate the
  # regular item instances on the order model.
  def items_dump=(items)
    items.each {|i| regular_items.build(i)}
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

    promotions = Promotion.all # Should be all current promotions
    promotions.each {|p| p.apply!(self) if p.qualifies?(self)}

    @_promotions_applied = true
  end

  def calculate_totals
    self.total = product_total + shipping_total
  end
end
