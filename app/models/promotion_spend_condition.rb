class PromotionSpendCondition < PromotionCondition
  desc  "Minimum Spend"
  condition_scope :order
  position 5

  metadata(:config) do
    float :amount, :required => true, :greater_than => 0, :default => 0
  end

  def check(order)
    if order.product_total >= SpookAndPuff::Money.new(amount.to_s)
      success
    else
      failure
    end
  end
end
