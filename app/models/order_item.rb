class OrderItem < ActiveRecord::Base
  # Turn off single-table inheritance
  self.inheritance_column = :_type_disabled

  belongs_to :promotion
  belongs_to :order
  belongs_to :sku

  attr_accessible :sku_id, :quantity

  validate :validate_stock_level
  validate :validate_purchase_limit

  after_initialize :initalize_totals

  # This callback is used to initialize any totals for this item. Will only
  # run if both a sku_id and quantity is specified and it is a new record.
  #
  # @return nil
  def initalize_totals
    if new_record? and !sku_id.blank? and !quantity.blank?
      calculate_prices_and_discounts
    end
  end

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
      order_items.quantity, order_items.adjusted_price,
      order_items.total, order_items.discount, skus.product_id,
      (SELECT name FROM products WHERE id = skus.product_id) || ' - ' || 
      (SELECT short_desc FROM products WHERE id = skus.product_id) AS sku_name
    }).joins(:sku)
  end

  # Overwrite the existing quantity with a new one.
  #
  # @param Integer amount
  #
  # @returns self
  def update_quantity(amount)
    self.quantity = amount
    calculate_prices_and_discounts
    valid?
    self
  end

  # Increment the existing quantity by the passed-in amount.
  #
  # @param Integer amount
  #
  # @returns self
  def increment_quantity(amount)
    self.quantity = quantity ? quantity + amount : amount
    valid?
    calculate_prices_and_discounts
    self
  end

  # Returns a summary of this order item. This includes the SKUs long
  # description and the quantity.
  #
  # @return String
  def description
    self[:description] || "#{sku.long_desc} (#{quantity})"
  end

  # Checks to see if the line item has had a discount applied to it.
  #
  # @return Boolean
  def discounted?
    discount > 0
  end

  # Either returns the total or returns the default of 0.0
  #
  # @return Float
  def total
    self[:total] || 0.0
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
    format_money(adjusted_price)
  end

  # Returns a formatted string of the item discount.
  #
  # @return String
  def formatted_discount
    format_money(discount)
  end

  private

  # This method is called when the item is initialized and every time the
  # quantity is adjusted. It's job is to determing what type of item this is
  # and calculate and store the various prices, totals and discounts.
  #
  # @return nil
  def calculate_prices_and_discounts
    self.discount = 0
    self.adjusted_price = self.original_price = sku.price

    if sku.batch_pricing? and quantity >= sku.batch_size
      self.type = 'batched'
      self.batch_price = sku.batch_price
      self.batch_size  = sku.batch_size

      batches = (quantity / batch_size).to_i
      remainder = quantity % batch_size

      self.total = self.original_total = (remainder * adjusted_price) + (batches * batch_price)
    else
      self.type = 'regular'
      self.total = self.original_total = adjusted_price * quantity
    end

    nil
  end

  # Checks to see that the current quantity for the item doesn't exceed the
  # amount actually in stock.
  def validate_stock_level
    if quantity > sku.stock_level
      errors.add(:stock_level, "exceeds available stock")
    end
  end

  # Checks to see that the current quantity for the item doesn't exceed the
  # purchase limit — if one is set.
  def validate_purchase_limit
    if sku.purchase_limiting? and quantity > sku.purchase_limit
      errors.add(:purchase_limit, "exceeds the purchase limit of #{sku.purchase_limit}")
      self[:quantity] = sku.purchase_limit
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
end
