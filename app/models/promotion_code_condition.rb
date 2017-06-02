class PromotionCodeCondition < PromotionCondition
  desc "Order has Code"
  condition_scope :order
  exclusivity_scope :code

  metadata(:config) do
    string :code, :required => true
  end

  before_validation :clean_code
  validate          :unique_code

  # An alias which provides the unique code as a single-element array
  # Used to simplify collecting all codes against a promotion
  #
  # @return Array<String>
  def codes
    [code]
  end

  def check(order)
    if order.promo_code.blank?
      failure(:no_promo_code, 'No code was provided')
    elsif order.promo_code.upcase != code
      partial(:promo_code_mismatch, "The code '#{order.promo_code.upcase}' isn't valid for this promotion.")
    else
      success
    end
  end

  def code_type
    'Shared'
  end

  private

  def unique_code
    unless code.blank?
      if !new_record?
        conditions = "AND id != #{id}"
      end
      if self.class.where("'code=>#{code}'::hstore <@ config #{conditions}").exists?
        errors.add(:code, 'has already been used')
      end
    end
  end

  def clean_code
    self.code = code.upcase
  end
end
