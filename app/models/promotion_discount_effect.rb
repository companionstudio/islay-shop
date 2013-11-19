class PromotionDiscountEffect < PromotionEffect
  include Promotions::DiscountEffectConfig

  desc "Whole Order Discount"
  condition_scope :order
  effect_scope :order

  def apply!(order, qualifications)
    case mode
    when 'percentage' 
      order.enqueue_adjustment(:percentage_discount, BigDecimal.new(percentage.to_s), 'promotion')
      result("Applied a #{percentage}% discount")
    when 'dollar'
      order.enqueue_adjustment(:fixed_discount, dollar, 'promotion')
      result("Applied a #{dollar} discount")
    end
  end
end
