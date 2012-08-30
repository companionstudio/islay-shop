class OrderBasket < Order
  # Increments the quantity for an item, specified by it's sku_id.
  #
  # @param [Integer, String] sku_id
  # @param Integer quantity
  #
  # @returns OrderItem
  def increment_item(sku_id, quantity)
    items.find_or_initialize(sku_id).tap {|i| i.increment_quantity(quantity)}
  end

  # Updates the quantity for an item, specified by it's sku_id. A quantity of 0
  # will result in the order being removed from the order.
  #
  # @param [Integer, String] sku_id
  # @param [Integer, String] quantity
  #
  # @returns OrderItem
  def update_item(sku_id, quantity)
    n = quantity.to_i
    item = items.find_or_initialize(sku_id)
    n == 0 ? items.delete(item) : item.update_quantity(n)
    item
  end

  # This is a shortcut for updating multiple items in one go. It replaces any
  # existing item quantities with the passed in values.
  #
  # @param Array<Hash, HashWithIndifferentAccess> items raw values for items
  #
  # @return Boolean
  def update_items(updates)
    # #update_item returns an OrderItem, which will have been validated, so here
    # we are constructing an array or booleans which indicate an error on the
    # items. We then reduce this to a single boolean using #any?, thus indicating
    # an error on at least one item.
    updates.map do |i|
      !update_item(i[:sku_id], i[:quantity]).errors.blank?
    end.any?
  end

  # Removes the a regular item specified by it's sku_id.
  #
  # @param [Integer] sku_id
  def remove_item(sku_id)
    items.delete(items.by_sku_id(sku_id))
  end

  # Apply a discount to a regular item by replacing it with an instance of a
  # discount_item.
  #
  # @param [Integer] sku_id to discount
  # @param [Integer] discount_price in cents
  # @param [Integer] discount_percentage in cents (proportion of discount_price of total)
  #
  # @todo Actually implment this guy.
  def discount_item(sku_id, discount_price, discount_percentage)

  end

  # Does what it says on the tin.
  #
  # @param [Integer] sku_id
  # @param [Integer] quantity
  #
  # @todo Actually implment this guy.
  def add_bonus_item(sku_id, quantity)

  end

  # Is a convenience method for promotion conditions. It returns a duplicate of
  # the regular_items association. The reason for this is because AR does
  # stupid things with association collections that haven't been saved to the
  # DB e.g. they don't actually respond to all the array methods.
  #
  # @return [Array<OrderItem>] duplicate array of order items
  def candidate_items
    @candidate_items ||= items.dup
  end
end
