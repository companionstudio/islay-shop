class OrderItem
  # An abstract module intended to be mixed into other more specific modules,
  # which are then mixed into associations on the Order model.
  #
  # Concretely, this module implements methods needed to add SKUs and services to
  # an order; it handles stock checks, selecting the correct price points and any
  # promotions/discounting.
  #
  # It must not be used directly, since some required methods are abstract and
  # need to be implemented by the target modules.
  module Purchasing
    # An error used to indicate an erroneous attempt to modify an item on an
    # order, when in fact, it doesn't exist.
    class OrderItemMissingError < StandardError
      # Initializes the error, duh
      #
      # @param Item item being purchased/updated
      #
      # @return OrderItemMissingError
      def initialize(item)
        @item = item
      end

      # Override this method so it's a little more descriptive.
      #
      # @return String
      def to_s
        "No matching order item for #{@item.class} with id #{@item.id}"
      end
    end

    # Returns the dollar total for all the items in the target association.
    #
    # @return SpookAndPuff::Money
    def total
      sum(:total)
    end

    # Returns the pre-discount dollar total for all the items in the target
    # association.
    #
    # @return SpookAndPuff::Money
    def pre_discount_total
      sum(:pre_discount_total)
    end

    # Returns the total quantity of skus for all the items in the target
    # association.
    #
    # @return Integer
    def quantity
      map(&:quantity).sum
    end

    # Returns the total quantity of non-bonus skus for all the items in the target
    # association.
    #
    # @return Integer
    def paid_quantity
      map(&:paid_quantity).sum
    end


    # This is the big, whoa-mamma method that drives most actions when
    # purchasing. It either finds or creates an order item for the purchase and
    # divides the specified quantity up amoungst the apppropriate price points.
    #
    # Setting the quantity to zero will result in the entry being removed.
    #
    # @param ActiveRecord::Base purchase
    # @param Integer n
    # @param ActveRecord::Base entry
    # @return ActiveRecord::Base
    def set_quantity(purchase, n, entry = find_or_create_item(purchase))

      if n == 0
        delete(entry)
      else
        entry.components.clear

        max_qty = maximum_quantity_allowed(purchase)

        if max_qty > n
          assign_components(entry, purchase, n)
        else
          assign_components(entry, purchase, max_qty)
          if !stock_available?(purchase, n)
            entry.errors.add(:quantity, "There #{max_qty > 1 ? 'are' : 'is'} only #{max_qty} of this item available.")
          elsif purchase_limited?(purchase)
            entry.errors.add(:quantity, "This item is limited to #{purchase.purchase_limit} per customer.")
          end
        end

        entry.quantity = entry.components.map(&:quantity).sum

        if entry.quantity == 0
          delete(entry)
        else
          entry.total = entry.components.reduce(SpookAndPuff::Money.new('0')) {|m, c| m + c.total }
          entry.pre_discount_total = entry.total
        end
      end

      entry
    end

    # A predicate which checks to see if there is an order item for the
    # provided purchase.
    #
    # @param Class purchase
    # @return [true, false]
    def has?(purchase)
      !find_item(purchase).nil?
    end

    # Returns the quantity for the specified purchase item.
    #
    # @param Class purchase
    # @return Integer
    def quantity_of(purchase)
      item = find_item(purchase)
      if item.nil?
        0
      else
        item.quantity
      end
    end

    # Sets the quantity and price for an item. This bypasses the bracketed
    # pricing entirely i.e. the item will not have any volume discounts.
    #
    # @param ActiveRecord::Base purchase
    # @param Integer n
    # @param SpookAndPuff::Money price
    # @param ActiveRecord::Base entry
    # @return ActiveRecord::Base
    # @todo Check and respect stock levels
    def set_quantity_and_price(purchase, n, price, entry = find_or_create_item(purchase))
      entry.components.clear
      update_entry(entry) do |i|
        i.components.build(:price => price, :quantity => n, :total => price * n)
      end
    end

    # Increments the quantity for an item.
    #
    # @param ActiveRecord::Base purchase
    # @param Integer n
    #
    # @return ActiveRecord::Base
    def increment_quantity(purchase, n)
      entry = find_or_create_item(purchase)
      set_quantity(purchase, (entry.quantity || 0) + n.to_i, entry)
    end

    # Decrements the quantity for a purchase. If the resulting quantity after
    # decrement is zero or less, the item is removed from the order.
    #
    # @param ActiveRecord::Base purchase
    # @param Integer n
    #
    # @return ActiveRecord::Base
    #
    # @raises OrderItemMissingError
    def decrement_quantity(purchase, n)
      entry = find_item_or_error(purchase)
      target = entry.quantity - n.to_i
      if target <= 0
        remove(purchase)
      else
        set_quantity(purchase, target, entry)
      end
    end

    # Removes an item from the order
    #
    # @param ActiveRecord::Base purchase
    #
    # @return ActiveRecord::Base
    def remove(purchase)
      entry = find_item(purchase)
      destroy(entry) if entry
    end

    # This is a noop by default, but can be over-ridden in specific associations.
    #
    # @return nil
    def purchase_stock!
      nil
    end

    # Finds an item within the association.
    #
    # @param [ActiveRecord::Base, Integer] purchase_or_id
    #
    # @return [ActiveRecord::Base, nil]
    def find_item(purchase_or_id)
      raise NotImplementedError
    end

    private

    # This is a utility function used to sum up monetary values from attributes
    # on entries in an association, while ensuring that it always returns a
    # SpookAndPuff::Money instance.
    #
    # @param Symbol attr
    #
    # @return SpookAndPuff::Money
    def sum(attr)
      if empty?
        SpookAndPuff::Money.new('0')
      else
        map(&attr).sum
      end
    end

    # A helper method which allows for operations to be performed on an entry,
    # then immediately after recalculating totals, discounts etc. The entry is
    # specified by the purchase.
    #
    # @param ActiveRecord::Base purchase
    # @param Symbol mode specifies if new entry is created or error thrown if it is missing.
    # @param Proc blk which recieves the entry after it's found or created.
    #
    # @return OrderItem
    #
    # @raises OrderItemMissingError
    def update_entry_for(purchase, mode, &blk)
      entry = case mode
      when :create then find_or_create_item(purchase)
      when :error then find_item_or_error(purchase)
      end

      update_entry(entry, &blk)
    end

    # A helper method which allows for operations to be performed on an entry,
    # then immediately after recalculating totals, discounts etc.
    #
    # @param ActiveRecord::Base purchase
    # @param Proc blk which recieves the entry after it's found or created.
    #
    # @return OrderItem
    def update_entry(entry, &blk)
      blk.call(entry)

      entry.pre_discount_total = entry.components.map(&:total).sum.round
      adjustments = entry.adjustments.reduce(SpookAndPuff::Money.zero) {|s, a| s + a.adjustment}
      entry.total = (entry.pre_discount_total + adjustments).round
      entry.quantity = entry.components.map(&:quantity).sum

      entry
    end

    def find_item_or_error(purchase)
      entry = find_item(purchase)
      if entry
        entry
      else
        raise OrderItemMissingError.new(purchase)
      end
    end

    def assign_components(entry, purchase, quantity)
      raise NotImplementedError
    end

    def stock_available?(purchase, n)
      raise NotImplementedError
    end

    def purchase_limited?(purchase)
      raise NotImplementedError
    end

    def maximum_quantity_allowed(sku)
      raise NotImplementedError
    end

    def find_or_create_item(sku)
      raise NotImplementedError
    end
  end
end
