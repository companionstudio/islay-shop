class PromotionShippingEffect < PromotionEffect
  desc "Discounts the shipping"
  effect_scope :service_items

  metadata(:config) do
    money :money
    float :percentage
    enum  :mode,  :required => true, :values => ['set', 'fixed', 'percentage'], :default => 'fixed'
  end

  validate :check_amount

  # Sets the amount for the effect. The value updated depends on the mode it
  # is in.
  #
  # @param [Numeric, String] n
  # @return [SpookAndPuff::Money, Numeric]
  def amount=(n)
    case mode
    when 'set', 'fixed' then self.money = n
    when 'percentage'   then self.percentage = n
    end
  end

  # Returns the amount. The underlying value chosen depends on the current
  # mode.
  #
  # @return [SpookAndPuff::Money, Numeric]
  def amount
    case mode
    when 'set', 'fixed' then money
    when 'percentage'   then percentage
    end
  end

  def apply!(order, results)
    shipping = Service.shipping_service
    item = order.find_item(shipping)

    discount = case mode
    when 'set'
      (SpookAndPuff::Money.new(money.to_s) - item.total).abs
    when 'fixed'
      SpookAndPuff::Money.new(money.to_s)
    when 'percentage'
      item.total.percent(percentage)
    end

    order.enqueue_adjustment(:discount_quantity, shipping, 1, discount, 'promotion')
    result("Discounted the shipping charges by #{discount}", item)
  end

  private

  # Checks to see that an amount has been set.
  #
  # @return nil
  def check_amount
    if (mode == 'percentage' and percentage == 0) or (mode == 'fixed' and money.zero?)
      errors.add(:amount, 'a discount cannot be zero')
    end
  end
end
