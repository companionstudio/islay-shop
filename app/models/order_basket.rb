class OrderBasket < Order
  # Increments the quantity for an item, specified by it's sku_id.
  #
  # @param [Integer, String] sku_id
  # @param Integer quantity
  #
  # @returns OrderItem
  def increment_item(sku_id, quantity)
    regular_items.find_or_initialize(sku_id).tap {|i| i.increment_quantity(quantity)}
  end

  # Updates the quantity for an item, specified by it's sku_id. A quantity of 0
  # will result in the order being removed from the order.
  #
  # @param [Integer, String] sku_id
  # @param Integer quantity
  #
  # @returns OrderItem
  def update_item(sku_id, quantity)
    item = regular_items.find_or_initialize(sku_id)
    quantity == 0 ? regular_items.delete(item) : item.update_quantity(quantity)
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
    regular_items.delete(regular_items.by_sku_id(sku_id))
  end

  # Apply a discount to a regular item by replacing it with an instance of a
  # discount_item.
  #
  # @param [Integer] sku_id to discount
  # @param [Integer] discount_price in cents
  # @param [Integer] discount_percentage in cents (proportion of discount_price of total)
  def discount_item(sku_id, discount_price, discount_percentage)
    item = regular_items.by_sku_id(sku_id)
    discount_items.build(
      :sku_id   => sku_id,
      :quantity => item.quantity,
      :price    => discount_price,
      :discount => discount_percentage
    )
    regular_items.delete(item)
  end

  # Does what it says on the tin.
  #
  # @param [Integer] sku_id
  # @param [Integer] quantity
  def add_bonus_item(sku_id, quantity)
    bonus_items.build(:sku_id => sku_id, :quantity => quantity)
  end

  # Is a convenience method for promotion conditions. It returns a duplicate of
  # the regular_items association. The reason for this is because AR does
  # stupid things with association collections that haven't been saved to the
  # DB e.g. they don't actually respond to all the array methods.
  #
  # @return [Array<OrderRegularItem>] duplicate array of order items
  def candidate_items
    @candidate_items ||= regular_items.dup
  end
end
