class OrderItem < ActiveRecord::Base
  belongs_to :promotion
  belongs_to :order
  belongs_to :sku

  before_validation :store_actual_price_and_total, :store_price_and_total, :store_discount

  attr_accessible :sku_id, :quantity

  validate :validate_stock_level
  validate :validate_purchase_limit

  # Used to count the total number of individual SKUs. Most useful when called
  # via an association. In fact, that's probably the only time you should use it.
  #
  # @return ActiveRecord::Relation
  def self.sku_total_quantity
    sum(:quantity)
  end

  # Adds calculated columns to a query to aid when making a summary listing of
  # order items
  #
  # @return ActiveRecord::Relation
  def self.summary
    select(%{
      order_items.type, order_items.quantity, order_items.price,
      order_items.total, order_items.discount, skus.product_id,
      (SELECT name FROM products WHERE id = skus.product_id) AS sku_name
    }).joins(:sku)
  end

  # Overwrite the existing quantity with a new one.
  #
  # @param Integer amount
  #
  # @returns self
  def update_quantity(amount)
    self.quantity = amount
    valid?
    self
  end

  # Increment the existing quantity by the passed-in amount.
  #
  # @param Integer amount
  #
  # @returns self
  def increment_quantity(amount)
    self.quantity = quantity ? quantityt + amount : amount
    valid?
    self
  end

  # Checks to see if the line item has had a discount applied to it.
  #
  # @return Boolean
  def discounted?
    discount > 0
  end

  # Returns a formatted string of the item total.
  #
  # @return String
  def formatted_total
    format_money(total)
  end

  # Returns a formatted string of the item price.
  #
  # @return String
  def formatted_price
    format_money(price)
  end

  # Returns a formatted string of the item discount.
  #
  # @return String
  def formatted_discount
    format_money(discount)
  end

  private

  # Checks to see that the current quantity for the item doesn't exceed the
  # amount actually in stock.
  def validate_stock_level
    if quantity > sku.stock_level
      errors.add(:stock_level, "")
    end
  end

  # Checks to see that the current quantity for the item doesn't exceed the
  # purchase limit — if one is set.
  def validate_purchase_limit
    if sku.purchase_limiting? and quantity > sku.purchase_limit
      errors.add(:purchase_limit, "exceeds the purchase limit of #{sku.purchase_limit}")
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

  def store_actual_price_and_total
    self.actual_price = sku.price
    self.actual_total = sku.price * quantity
  end

  def store_price_and_total
    self.price = actual_price if price.blank?
    self.total = actual_total if total.blank?
  end

  def store_discount
    self.discount = actual_total - total
  end
end
