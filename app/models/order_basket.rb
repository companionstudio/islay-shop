class OrderBasket < Order

  before_create :store_reference
  after_create :send_thank_you_mail

  # Finds the quantity of the specified SKU in the order. This can be between
  # 0 and n.
  #
  # @return Integer
  def sku_quantity(sku)
    item = items.find {|i| i.sku_id == sku.id}
    item ? item.quantity : 0
  end

  # The total number of items in the order
  #
  # @return Integer
  def total_sku_quantity
    items.reduce(0) {|a, i| a + i.quantity}
  end

  # Finds a line item, based on a sku
  #
  # @return Item
  def find_item_by_sku(sku)
    items.find {|i| i.sku_id == sku.id}
  end

  # Attempts to authorize a payment method on spreedly core.
  #
  # @return Boolean
  def process_add!
    if credit_card_payment.valid? and credit_card_payment.authorize!
      skus = Hash[items.map {|i| [i.sku_id, i.quantity]}]
      Sku.purchase_stock!(skus)
      next!("Authorizing #{formatted_total}")
    else
      fail!
    end
  end

  # Attempts to generate a reference for the order. Since the reference needs to
  # be unique and is generated rather than being a serial value, we attempt to
  # generate it five times. On failure, we raise an error.
  #
  # @return String
  def store_reference
    5.times do
      self[:reference] = generate_reference
      return reference unless self.class.where(:reference => reference).first
    end

    raise "Could not generate unique reference for order"
  end

  # Generates a reference using the time, and a 6 char hex string.
  #
  # @return String
  def generate_reference
    "#{Time.now.strftime('%y%m')}-#{SecureRandom.hex(3).upcase}"
  end

  # Sends the thank you email when the order is successfully created
  def send_thank_you_mail
    IslayShop::OrderMailer.thank_you(self).deliver
  end

  # Updates the details of the order — contact, addresses etc. Also recalculates
  # the order totals, since shipping calculators might rely on any of the
  # details in here.
  #
  # @return nil
  def update_details(details)
    self.attributes = details
    calculate_totals
    nil
  end

  # Increments the quantity for an item, specified by it's sku_id.
  #
  # @param [Integer, String] sku_id
  # @param Integer quantity
  #
  # @returns OrderItem
  def increment_item(sku_id, quantity, recalculate = true)
    items.find_or_initialize(sku_id).tap do |i|
      increment = i.increment_quantity(quantity.to_i)
      errors.add("order_item_#{sku_id}", increment.errors) unless increment.errors.blank?
      calculate_totals if recalculate
    end
  end

  # Updates the quantity for an item, specified by it's sku_id. A quantity of 0
  # will result in the order being removed from the order.
  #
  # @param [Integer, String] sku_id
  # @param [Integer, String] quantity
  #
  # @returns OrderItem
  def update_item(sku_id, quantity, recalculate = true)
    n = quantity.to_i
    items.find_or_initialize(sku_id).tap do |i|
      n == 0 ? items.delete(i) : i.update_quantity(n)
      calculate_totals if recalculate
    end
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
    result = updates.map {|i| !update_item(i[:sku_id], i[:quantity], false).errors.blank? }.any?
    calculate_totals
    result
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
