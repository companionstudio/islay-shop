class Order
  module Purchasing
    # Updates the quantities of multiple items.
    #
    # @params Hash updates
    #
    # @return Array<ActiveRecord::Base>
    #
    # @todo This currently encodes Skus. Will have to be polymorphic in the
    # future.
    def update_quantities(updates)
      updates.map {|id, n| set_quantity(Sku.find(id), n.to_i)}
    end

    # Sets the quantity for an item, overwriting any existing quantities.
    #
    # @param ActiveRecord::Base item
    # @param Integer quantity
    #
    # @return ActiveRecord::Base
    def set_quantity(purchase, quantity)
      for_purchase(purchase, :set_quantity, true, quantity)
    end

    # Sets the quantity and price for an item. This bypasses the bracketed
    # pricing entirely i.e. the item will not have any volume discounts.
    #
    # @param ActiveRecord::Base purchase
    # @param Integer n
    # @param SpookAndPuff::Money price
    # @param Hash opts
    # @option opts [true, false] :retotal
    #
    # @return ActiveRecord::Base
    def set_quantity_and_price(purchase, n, price, opts = {})
      _opts = {:retotal => true}.merge(opts)
      for_purchase(purchase, :set_quantity_and_price, _opts[:retotal], n, price)
    end

    # Increments the quantity for an item.
    #
    # @param ActiveRecord::Base item
    # @param Integer quantity
    #
    # @return ActiveRecord::Base
    def increment_quantity(purchase, quantity)
      for_purchase(purchase, :increment_quantity, true, quantity)
    end

    # Decrements the quantity of an item. If it is decremented to zero or less
    # then the item is removed
    #
    # @param ActiveRecord::Base item
    # @param Integer quantity
    #
    # @return ActiveRecord::Base
    def decrement_quantity(purchase, quantity)
      for_purchase(purchase, :decrement_quantity, true, quantity)
    end

    # Removes an item from the order.
    #
    # @param ActiveRecord::Base item
    #
    # @return ActiveRecord::Base
    def remove(purchase)
      for_purchase(purchase, :remove, true)
    end

    # Finds an item against the order.
    #
    # @param ActiveRecord::Base
    #
    # @return ActiveRecord::Base
    def find_item(purchase)
      item_association_for_purchase(purchase).find_item(purchase)
    end

    private

    # Finds the item association for a purchasable e.g. sku_items for a Sku.
    #
    # @param ActiveRecord::Base
    #
    # @return ActiveRecord::Relation
    def item_association_for_purchase(purchase)
      send(:"#{purchase.class.to_s.underscore}_items")
    end

    # A helper which will run a particular action against a relation/assocation
    # based on the purchasable provided e.g. passing in a Sku will run the action
    # against sku_items.
    #
    # @param ActiveRecord::Base purchase
    # @param Symbol action
    # @param [true, false] recalculate
    #
    # @return ActiveRecord::Base
    #
    # @todo Currently fixed to the sku_items association.
    def for_purchase(purchase, action, recalculate, *args)
      result = if !args.empty?
        item_association_for_purchase(purchase).send(action, purchase, *args)
      else
        item_association_for_purchase(purchase).send(action, purchase)
      end

      calculate_totals if recalculate

      result
    end
  end
end
