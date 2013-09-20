class PromotionCodeCondition < PromotionCondition
  desc "Order has Code"
  condition_scope :order

  metadata(:config) do
    string :code, :required => true
  end

  before_validation :clean_code
  validate          :unique_code

  def check(order)
    if order.promo_code.blank?
      failure(:no_promo_code, "A promotion code has not been entered")
    elsif order.promo_code.upcase != code
      partial(:promo_code_mismatch, "The code '#{order.promo_code}' does not match")
    else
      success
    end
  end

  private

  def unique_code
    if !new_record?
      conditions = "AND id != #{id}"
    end
    if self.class.where("'code=>#{code}'::hstore <@ config #{conditions}").exists?
      errors.add(:code, 'has already been used')
    end
  end

  def clean_code
    self.code = code.upcase
  end
end