class OrderItem
  # This module contains the logic and associations used by orders to handle
  # the addition of bonuses, discounting and upward adjustments at the order item
  # level
  #
  # It relies on the OrderPurchasing and OrderItemPurchasing modules,
  # specifically the logic for choosing associations and updating entries.
  module Adjustments
    # Discounts the specified quantity for a purchase.
    #
    # @param ActiveRecord::Base purchase
    # @param Integer quantity
    # @param [Float, Integer] discount
    # @return OrderItem
    # @raises OrderItemMissingError
    def discount_quantity(purchase, quantity, discount, source = 'manual')
      item = find_item_or_error(purchase)
      adjust_item('line_level', item, quantity, -(discount.abs) * quantity, source)
    end

    # Adds a percentage discount for a purchase.
    #
    # @param ActiveRecord::Base purchase
    # @param Integer quantity
    # @param Numeric discount
    # @param String source
    # @return OrderItem
    # @raises OrderItemMissingError
    def percentage_discount(purchase, quantity, discount, source = 'manual')
      item = find_item_or_error(purchase)
      _discount = item.total.percent(discount)
      adjust_item('line_level', item, quantity, -_discount, source)
    end

    # Adds a fixed discount for a purchase.
    #
    # @param ActiveRecord::Base purchase
    # @param Integer quantity
    # @param SpookAndPuff::Money discount
    # @param String source
    # @return OrderItem
    # @raises OrderItemMissingError
    def fixed_discount(purchase, quantity, discount, source = 'manual')
      item = find_item_or_error(purchase)
      adjust_item('line_level', item, quantity, -(discount.abs) * quantity, source)
    end

    # Promote the specified quantity for a purchase.
    #
    # @param ActiveRecord::Base purchase
    # @param Integer quantity
    # @return OrderItem
    def add_bonus_quantity(purchase, quantity, source)

      update_entry_for(purchase, :create) do |entry|
        bonus = entry.components.bonus
        if bonus
          bonus.quantity  = bonus.quantity + quantity
          bonus.total     = bonus.price * bonus.quantity
          value           = bonus.total
        else
          point = purchase.price_points.where(:mode => 'single', :current => true).first
          price = point.price
          value = price * quantity

          entry.components.build(
            :price    => price,
            :quantity => quantity,
            :total    => value,
            :kind     => 'bonus'
          )
        end

        adjust_item('bonus', entry, quantity, -value, source)
      end
    end

    # Distributes the discount as a percentage of the order total amongst the
    # order items.
    #
    # @param [Integer, Float] percentage
    # @param String source
    # @return SpookAndPuff::Money
    def distribute_discount(percentage, source)
      reduce(SpookAndPuff::Money.new('0')) do |total_discount, item|
        discount = item.total.percent(percentage)
        if item.paid_quantity > 0 and discount.positive?
          adjust_item('order_level', item, item.paid_quantity, -discount, source)
          total_discount + discount
        else
          total_discount
        end
      end
    end

    # Distributes an increase as a percentage of the order total across all the
    # order items.
    #
    # @param Numeric percentage
    # @param String source
    # @return SpookAndPuff::Money
    def distribute_increase(percentage, source)
      reduce(SpookAndPuff::Money.new('0')) do |total_increase, item|
        increase = item.total.percent(percentage)
        if item.paid_quantity > 0 and increase.positive?
          adjust_item('order_level', item, item.paid_quantity, increase, source)
          total_increase + increase
        else
          total_increase
        end
      end
    end

    # Removes adjustments of the specified source and kind.
    #
    # @param String source
    # @param String kind
    # @return nil
    def remove_adjustments(source, kind = nil)
      each do |item|
        update_entry(item) do
          candidates = item.adjustments.select  do |a|
            if kind
              a.source == source and a.kind == kind
            else
              a.source == source
            end
          end
          item.adjustments.delete(candidates)
        end
      end
      nil
    end

    # Set the total amount for this item, regardless of quantity
    #
    # @param ActiveRecord::Base purchase
    # @param [Float, Integer] amount
    # @return OrderItem
    # @raises OrderItemMissingError
    # @raises PriceBelowZeroError
    def set_manual_item_total(purchase, amount)
      raise PriceBelowZeroError.new(amount) if amount < 0
      item = find_item_or_error(purchase)
      update_entry(item) do |item|
        adjustment = item.adjustments.by_source_and_kind('manual', 'set_unit_price') || item.adjustments.build

        adjustment.attributes = {
          :kind         => 'set_item_total',
          :manual_price => amount.to_s,
          :source       => 'manual'
        }
      end
    end

    # Set the unit price for this item.
    #
    # @param ActiveRecord::Base purchase
    # @param [Float, Integer] price
    # @return OrderItem
    # @raises OrderItemMissingError
    # @raises PriceBelowZeroError
    def set_manual_unit_price(purchase, price)
      raise PriceBelowZeroError.new(price) if price < 0
      item = find_item_or_error(purchase)

      update_entry(item) do |item|
        adjustment = item.adjustments.by_source_and_kind('manual', 'set_unit_price') || item.adjustments.build

        adjustment.attributes = {
          :kind         => 'set_unit_price',
          :manual_price => price.to_s,
          :source       => 'manual'
        }
      end
    end

    # Adds an adjustment to an order item. This is used to add bonus items,
    # discounts or otherwise tweak the total price for an order item.
    #
    # To adjust up, use the companion method #adjust_up_for_purchase
    #
    # @param Symbol kind represents the type of adjustment e.g. line level, order level
    # @param ActiveRecord::Base purchase
    # @param Integer quantity
    # @param SpookAndPuff::Money amount
    # @param String source of the adjustment
    # @return OrderItem
    def adjust_item(kind, item, quantity, amount, source)
      update_entry(item) do |item|
        adjustment = if source == "manual"
          item.adjustments.by_source_and_kind(source, kind).first || item.adjustments.build
        elsif source == "promotion"
          # Promotion adjustments can be added cumulatively
          item.adjustments.build
        end

        adjustment.attributes = {
          :kind       => kind,
          :quantity   => quantity,
          :adjustment => amount,
          :source     => source
        }
      end
    end

    def paid_total
      reduce(SpookAndPuff::Money.zero) do |a, i|
        a + i.paid_total
      end
    end


  end
end
