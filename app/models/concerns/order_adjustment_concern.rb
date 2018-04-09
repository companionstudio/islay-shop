# This module contains the logic and associations used by orders to handle
# the addition of bonuses, discounting and upward adjustments at both the order
# and the order item level.
#
# It relies on the OrderPurchasing and OrderItemPurchasing modules,
# specifically the logic for choosing associations and updating entries.
module OrderAdjustmentConcern
  extend ActiveSupport::Concern
  # Callback used to scaffold the associations.
  #
  # @param ActiveRecord::Base klass
  # @return ActiveRecord::Base
  def self.included(klass)
    klass.has_many :adjustments, :through => :items, :autosave => true
    klass.before_validation :check_for_and_run_adjustments
  end

  # Enqueues an adjustment to be run at a later point.
  #
  # @param Symbol meth
  # @param Array args
  # @return Symbol
  def enqueue_adjustment(meth, *args)
    @adjustments_queue ||= []
    @adjustments_queue << [meth, args]

    meth
  end

  # A map of the adjustment types to the underlying method, ordered by the
  # priority in which they should be applied.
  ADJUSTMENT_PRIORITIES = [
    :manual_to_zero,
    :bonus_quantity,
    :discount_quantity,
    :fixed_item_discount,
    :percentage_item_discount,
    :fixed_discount,
    :fixed_increase,
    :percentage_discount,
    :manual_unit_price,
    :manual_item_total
  ].freeze

  # Reorders and applies pending adjustments.
  #
  # @return [true, false]
  def apply_adjustments!
    if @adjustments_queue and !@adjustments_queue.empty?
      grouped = @adjustments_queue.group_by {|a| a.first}
      ADJUSTMENT_PRIORITIES.each do |p|
        if grouped[p]
          meth = :"set_#{p}"
          grouped[p].each do |a|
            send(meth, *a.last)
            calculate_totals
          end
        end
      end

      @adjustments_queue = []

      true
    else
      false
    end
  end

  # This will remove adjustments at the order and item level based on thier
  # source. For example, this can be used to remove all 'promotion'
  # adjustments.
  #
  # @param String source
  # @return nil
  def remove_adjustments(source, kind = 'order_level')
    adjustments.delete(adjustments.select {|a| a.source == source})

    sku_items.remove_adjustments(source, kind)
    service_items.remove_adjustments(source, kind)

    nil
  end

  # Set the total of the entire order to the given amount
  #
  # @param ActiveRecord::Base purchase
  # @param SpookAndPuff::Money manual_total
  # @return OrderItem
  def set_manual_order_total(manual_total, source = 'manual')
    amount = total - manual_total
    if amount > SpookAndPuff::Money.zero
      set_fixed_discount(amount.abs, source)
    else
      set_fixed_increase(amount.abs, source)
    end
  end


  private

  # Remove all manual adjustments
  #
  # @return nil
  def set_manual_to_zero
    remove_adjustments('manual')
  end

  # Checks to see if there are any adjustments pending, runs them if there are,
  # then calculates the totals.
  #
  # @return nil
  def check_for_and_run_adjustments
    if @adjustments_queue and !@adjustments_queue.empty?
      apply_adjustments!
    end
    nil
  end

  # Discounts the specified quantity of a purchase by the amount specified.
  # This discount is per purchase, so the resulting discount will be quantity
  # times discount.
  #
  # @param ActiveRecord::Base purchase
  # @param Integer quantity
  # @param SpookAndPuff::Money discount
  # @return OrderItem
  # @raises OrderItemMissingError
  def set_discount_quantity(purchase, quantity, discount, source)
    for_purchase(purchase, :discount_quantity, false, quantity, discount, source)
  end

  # Sets a the specified quantity of a purchase as a bonus. If this item is
  # already in the order, it will add an additional 'bonus' component.
  #
  # @param ActiveRecord::Base purchase
  # @param Integer quantity
  # @return OrderItem
  def set_bonus_quantity(purchase, quantity, source)
    for_purchase(purchase, :add_bonus_quantity, false, quantity, source)
  end

  # Discounts a purchase by the fixed amount.
  #
  # @param ActivRecord::Base purchase
  # @param Integer quantity
  # @param SpookAndPuff::Money discount
  # @param String source
  # @return OrderItem
  def set_fixed_item_discount(purchase, quantity, discount, source)
    for_purchase(purchase, :fixed_discount, false, quantity, discount, source)
  end

  # Discounts a purchase by the percentage amount.
  #
  # @param ActivRecord::Base purchase
  # @param Integer quantity
  # @param Numeric discount
  # @param String source
  # @return OrderItem
  def set_percentage_item_discount(purchase, quantity, discount, source)
    for_purchase(purchase, :percentage_discount, false, quantity, discount, source)
  end

  # Modifys the total on an order and distributes the discount across the items
  # in the order.
  #
  # @param SpookAndPuff::Money amount
  # @return self
  # @raises ExcessiveDiscountError
  def set_fixed_discount(amount, source)
    raise ExcessiveDiscountError.new(amount, total) if amount > original_total

    create_adjustment(amount, :down, source)

    percentage = total.proportion(amount)

    sku_items.distribute_discount(percentage, source)
    service_items.distribute_discount(percentage, source)

    self
  end

  # Modifys the total on an order and distributes the discount across the items
  # in the order.
  #
  # @param [Fixnum, Integer] percentage
  # @return self
  # @raises ExcessiveDiscountError
  def set_percentage_discount(percentage, source)
    amount = total.percent(percentage)
    raise ExcessiveDiscountError.new(amount, total) if amount > original_total
    sku_items.distribute_discount(percentage, source)
    service_items.distribute_discount(percentage, source)
    self
  end

  # Modifies the total of an order upwards and distributes the increase across
  # the items in the order.
  # @param SpookAndPuff::Money amount
  # @param String source specifies the origin of the adjustment e.g. promotion/manual
  # @return self
  def set_fixed_increase(amount, source)
    percentage = total.proportion(amount)
    create_adjustment(amount, :up, source)
    sku_items.distribute_increase(percentage, source)
    service_items.distribute_increase(percentage, source)

    self
  end


  # Set the unit price of an item in the order.
  #
  # @param ActiveRecord::Base purchase
  # @param SpookAndPuff::Money amount
  # @return OrderItem
  def set_manual_unit_price(purchase, amount)
    for_purchase(purchase, :set_manual_unit_price, false, amount)
  end

  # Set the item total of an item in the order
  #
  # @param ActiveRecord::Base purchase
  # @param SpookAndPuff::Money amount
  # @return OrderItem
  def set_manual_item_total(purchase, amount)
    for_purchase(purchase, :set_manual_item_total, false, amount)
  end

  # Generates an order level adjustment. Has the side effect of mutating
  # existing 'manual' adjustments.
  #
  # @param SpookAndPuff::Money amount
  # @param [:up, :down] direction
  # @param ['manual', 'promotion'] source
  # @return OrderAdjustment
  def create_adjustment(amount, direction, source)
    record = case source
    when 'manual'     then adjustments.manual || adjustments.build(:source => 'manual')
    when 'promotion'  then adjustments.build(:source => 'promotion')
    when 'offer'      then adjustments.build(:source => 'offer')
    end

    record.adjustment = case direction
    when :up    then amount
    when :down  then -amount
    end

    record
  end

  # An error used to indicate an attempt to discount an order with an amount in
  # excess of it's total.
  class ExcessiveDiscountError < StandardError
    def initialize(discount, total)
      @discount = discount
      @total = total
    end

    def to_s
      "You can't apply a discount of #{@discount}, since the order total is only #{@total}"
    end
  end

  # Indicates an attempt to manually set an item's price to less than zero.
  class PriceBelowZeroError < StandardError
    def initialize(price)
      @discount = price
    end

    def to_s
      "You can't set the price of an order or item to less than zero."
    end
  end
end
