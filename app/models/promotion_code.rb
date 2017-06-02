class PromotionCode < ActiveRecord::Base
  belongs_to    :promotion_condition, :class_name => 'PromotionUniqueCodeCondition'
  has_many      :applied_promotions
  has_many      :orders, :through => :applied_promotions
  validates     :code, :uniqueness => true
  before_create :generate_code
  attr_accessor :prefix, :suffix

  def redeem!(order)
    order.applied_promotions.first{|ap|ap.promotion_id == promotion_condition.promotion_id}.update_attribute(:promotion_code_id, id)
    update_attribute(:redeemed_at, Time.now)
  end

  private

  # A before_create hook that generates a unique code based on the supplied
  # prefix and suffix.
  #
  # @param Integer attempts
  #
  # @return nil
  def generate_code(attempts = 0)
    if attempts > 4
      raise "Could not generate unique code"
    else
      self[:code] = "#{prefix}#{SecureRandom.hex(3)}#{suffix}".upcase
      generate_code(attempts + 1) if self.class.exists?(:code => code)
    end
  end
end
