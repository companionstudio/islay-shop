class OrderBasket < Order
  # This error class is used when there is an attempt to purchase more of a
  # particular SKU than is allowed.
  class PurchaseLimitError < StandardError
    def initialize(quantity, sku)
      @quantity = quantity
      @sku = sku
    end

    def to_s
      "The quantity of #{@quantity} exceeds the purchase limit for #{@sku.long_desc}"
    end
  end

  # Adds or updates an item based on the sku_id. If the item exists, it's
  # quantity is incremented by the specified amount, otherwise a new item is
  # created.
  #
  # @param [Integer] sku_id the SKU to add or update
  # @param [Integer] quantity to add to the order
  # @param [Symbol] mode specifies updating or overwriting entries, `:add` or `:update`
  #
  # @raises PurchaseLimitError
  #
  # @todo This action needs to account for and handle exhausted stock levels.
  def add_or_update_item(sku_id, quantity, mode = :add)
    sku_id    = sku_id.to_i
    quantity  = quantity.to_i

    item = regular_items.by_sku_id(sku_id)

    if item and quantity == 0
      regular_items.delete(item)
    else
      item ||= regular_items.build(:sku_id => sku_id)
      item.quantity = if item.quantity.blank?
        quantity
      else
        case mode
        when :add     then item.quantity + quantity
        when :update  then quantity
        end
      end

      if item.sku.purchase_limiting? and item.quantity > item.sku.purchase_limit
        raise PurchaseLimitError.new(quantity, item.sku)
      end
    end
  end

  # This is a shortcut for updating multiple items in one go. It replaces any
  # existing item quantities with the passed in values.
  #
  # @param [Hash] items raw values for items
  def update_items(items)
    items.each {|k, i| add_or_update_item(i[:sku_id], i[:quantity], :update)}
    nil
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
