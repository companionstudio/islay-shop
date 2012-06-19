class Order < ActiveRecord::Base
  belongs_to  :person
  has_one     :credit_card_payment
  has_many    :items,            :class_name => 'OrderItem'
  has_many    :bonus_items,      :class_name => 'OrderBonusItem'
  has_many    :discount_items,   :class_name => 'OrderDiscountItem'

  # This association has an extra method attached to it. This is so we can
  # easily retrieve an item by it's sku_id, which is necessary for both
  # #add_item and #remove_item.
  #
  # It is implemented so it can handle the case the there items are in memory
  # only, or where they are persisted in the DB.
  has_many :regular_items, :class_name => 'OrderRegularItem' do
    def find_or_create_by_sku_id(sku_id)
      if loaded?
        select {|i| i.sku_id == sku_id}.first
      else
        where(:sku_id => sku_id).first
      end
    end
  end

  accepts_nested_attributes_for :regular_items
  before_save :calculate_totals
  track_user_edits

  # Generates and order from a JSON object.
  def self.load(json, apply = true)
    order = Order.new(JSON.parse(json))
    order.apply_promotions if apply
    order
  end

  DUMP_OPTS = {
    :except   => [
      :payment_token, :payment_number, :payment_name, :payment_expiry_date,
      :order_status, :processing_status, :created_at, :updated_at, :shipping_total,
      :product_total, :total
    ],
    :methods => [:use_member_address, :use_member_details],
    :include  => {:regular_items => {:except => [:id, :order_id, :created_at, :updated_at]}}
  }.freeze

  # Generates a JSON string representation of the order and it's items. It
  # only dumps the regular items and their quantities. Bonus and discount
  # details are ignored, since they are reapplied when the order is loaded.
  def dump
    # Ignore bonus items
    # Dump discount and regular items, but omit the type. When they're loaded
    # again, they'll be treated as regular items. A clean slate ready for
    # promotion application.
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
  def add_or_update_item(sku_id, quantity)
    item = regular_items.by_sku_id(sku_id) || regular_items.build(:sku_id => sku_id)
    item.quantity = if item.quantity.blank?
      quantity
    else
      item.quantity + quantity
    end
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

  protected

  class PromotionApplyError < StandardError
    def message
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

    promotions = Promotions.all # Should be all current promotions
    promotions.each {|p| p.apply!(self) if p.qualifies?(self)}

    @_promotions_applied = true
  end

  def calculate_totals
    self.total = product_total + shipping_total
  end
end
