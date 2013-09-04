class OrderItem < ActiveRecord::Base
  extend SpookAndPuff::MoneyAttributes
  attr_money :total, :pre_discount_total

  belongs_to :promotion
  belongs_to :order
  
  has_many :components, :class_name => 'OrderItemComponent', :dependent => :destroy, :autosave => true do
    # Returns the component with the specified price.
    #
    # @param Float price
    #
    # @return [OrderItemComponent, nil]
    def by_price(price)
      select {|c| c.price == price and c.kind == 'regular'}.first
    end

    # @return OrderItemComponent
    def bonus
      select {|c| c.kind == 'bonus'}.first
    end

    # @return OrderItemComponent
    def manual
      select {|c| c.kind == 'manual'}.first
    end
  end

  attr_accessible :quantity

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

  # A description of this item. Should be implemented by sub-classes.
  #
  # @return String
  def description
    raise NotImplementedError
  end
  
  # Checks to see if any of the components have been flagged as bonuses.
  #
  # @return Boolean
  def bonus?
    components.map(&:bonus?).any?
  end

  # Checks to see if this item has only bonus components.
  #
  # @return Boolean
  def only_bonus?
    bonus? and components.length == 1
  end

  # Summaries the price and quantity of each component.
  #
  # @return String
  def price_summary
    if only_bonus?
      "Free!"
    else
      if components.length == 1
        components.first.price
      else
        components.sort {|x, y| x.quantity <=> y.quantity}.map do |c|
          price = c.price.zero? ? "Free" : "at #{c.price}"
          "#{c.quantity} #{price}"
        end.join(', ')
      end
    end
  end

  # Calculates a discount from the pre-discount total and total.
  #
  # @return SpookAndPuff::Money
  def discount
    @discount ||= pre_discount_total - total
  end

  # @todo Deprecate this alias
  alias :formatted_discount :discount
  alias :formatted_total :total

  # Checks to see if the line item has had a discount applied to it.
  #
  # @return [true, false]
  def discounted?
    !discount.zero?
  end
  
  # Calculates the quantity of non-bonus components.
  #
  # @return [Float, Number]
  def paid_quantity
    @paid_quantity ||= components.reject {|c| c.kind == 'bonus'}.map(&:quantity).sum
  end

  private

  # Formats a float into a monentary formatted string i.e. sticks a '$' in the
  # front and pads the decimals.
  #
  # @param Float value
  # @return String
  def format_money(value)
    value
  end
end
