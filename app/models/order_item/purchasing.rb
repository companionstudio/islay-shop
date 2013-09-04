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
      entry.quantity = n
      
      if n == 0
        delete(entry)
      else
        entry.components.clear
         
        if stock_available?(purchase, n)
          assign_components(entry, purchase, n)
        else
          # Add some error
          assign_components(entry, purchase, maximum_quantity_allowed(purchase))
        end

        entry.total = entry.components.reduce(SpookAndPuff::Money.new('0')) {|m, c| m + c.total }
        entry.pre_discount_total = entry.total
      end

      entry
    end

    # Sets the quantity and price for an item. This bypasses the bracketed 
    # pricing entirely i.e. the item will not have any volume discounts.
    # 
    # @param ActiveRecord::Base purchase
    # @param Integer n
    # @param SpookAndPuff::Money price
    # @param ActiveRecord::Base entry
    #
    # @return ActiveRecord::Base
    def set_quantity_and_price(purchase, n, price, entry = find_or_create_item(purchase))
      entry.components.clear
      entry.quantity = n

      total = SpookAndPuff::Money.new(price) * quantity
      entry.components.build(:price => price, :quantity => n, :total => total)
      entry.total = entry.pre_discount_total = total

      entry
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
      entry.total = (entry.pre_discount_total + entry.adjustments.map(&:adjustment).sum).round
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

    def maximum_quantity_allowed
      raise NotImplementedError
    end

    def find_or_create_item(sku)
      raise NotImplementedError
    end
  end
end
