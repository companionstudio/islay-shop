class PromotionApplicationObserver < ActiveRecord::Observer
  observe :order

  # This hook checks to see if it needs to disable promotions that have an 
  # application limit on them.
  #
  # @return nil
  def after_create(order)
    order.promotions.each do |p|
      if p.application_limit? and p.orders.count >= p.application_limit
        p.update_attribute(:active, false)
      end

      if p.unique_code_based?
        code = PromotionCode.where(:code => order.promo_code).first
        code.redeem!(order) if code
      end
    end
  end
end

