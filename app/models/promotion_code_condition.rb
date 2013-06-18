class PromotionCodeCondition < PromotionCondition
  desc "Order has Code"

  metadata(:config) do
    string :code, :required => true
  end

  before_validation :clean_code
  validate          :unique_code

  def qualifications(order)
    if qualifies?(order)
      {:order => 1}
    else
      {:order => 0}
    end
  end

  def qualifies?(order)
    order.promo_code and order.promo_code.upcase == code
  end

  def check_qualification(order)
    if order.promo_code.nil?
      result(false, :no_code_provided)
    else
      if order.promo_code.upcase == code
        result(true)
      else
        result(false, :invalid_code)
      end
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