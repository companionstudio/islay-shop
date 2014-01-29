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

    # Any components that are not bonuses.
    #
    # @return Array<OrderItemComponent>
    def non_bonus
      select {|c| c.kind != 'bonus'}
    end
  end

  has_many :adjustments, :class_name => 'OrderItemAdjustment', :dependent => :destroy, :autosave => true do
    # Returns any adjustments up.
    #
    # @return Array<OrderItemAdjustment>
    def up
      select {|a| a.adjustment > 0}
    end

    # Returns any adjustments down.
    #
    # @return Array<OrderItemAdjustment>
    def down
      select {|a| a.adjustment < 0}
    end

    # Return adjustments of a particular source and kind
    #
    # @param String source
    # @param String kind
    #
    # @return [nil, OrderItemAdjustment]
    def by_source_and_kind(source, kind)
      select {|a| a.kind == kind and a.source == source}
    end

    # If it exists, returns the manual adjustment on this item.
    #
    # @return [nil, OrderItemAdjustment]
    def manual
      select {|a| a.source == 'manual'}.first
    end

    # Return any manual adjustments applied directly to the item
    #
    # @return [nil, OrderItemAdjustment]
    def manual_item_level
      select {|a| ['line_level', 'item_adjustment', 'set_unit_price', 'set_item_total'].include? a.kind and a.source == 'manual'}
    end

    # Return any manual adjustments that have come from the order level
    #
    # @return [nil, OrderItemAdjustment]
    def manual_order_level
      by_source_and_kind('manual', 'order_level').first
    end

    # Return any adjustment that sets a unit price on the item
    #
    # @return [nil, OrderItemAdjustment]
    def unit_price
      select {|a| a.kind == 'set_unit_price'}.first
    end

    # Return any adjustment that sets a manual total on the item
    #
    # @return [nil, OrderItemAdjustment]
    def item_total
      select {|a| a.kind == 'set_item_total'}.first
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

  # Checks to see if this item has only non-bonus components.
  #
  # @return Boolean
  def only_paid?
    !bonus?
  end

  # Checks to see if this item has both bonus and non-bonus components.
  #
  # @return Boolean
  def paid_and_bonus?
    bonus? and !only_bonus?
  end

  # Summaries the price and quantity of each component.
  #
  # @param Hash options - passes options to spookAndPuff::Money's to_s method
  #
  # @return String
  def price_summary(options = {})
    if only_bonus?
      "Free!"
    elsif components.length == 1
      components.first.price.to_s(options)
    else
      non_bonus = components.non_bonus.sort {|x, y| x.quantity <=> y.quantity}
      bonus     = components.bonus
      summaries = non_bonus.map {|c| "#{c.quantity} at #{c.price.to_s(options)}"}

      if bonus
        (summaries << "#{bonus.quantity} free").join(', ')
      else
        summaries.join(', ')
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
    components.reject {|c| c.kind == 'bonus'}.map(&:quantity).sum
  end

  private
end
