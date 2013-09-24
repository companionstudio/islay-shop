class PromotionCode < ActiveRecord::Base
  belongs_to    :order
  belongs_to    :condition, :class_name => 'PromotionUniqueCodeCondition'
  validates     :code, :uniqueness => true
  before_create :generate_code
  attr_accessible :prefix, :suffix
  attr_accessor :prefix, :suffix

  def redeem!(order)
    update_attributes(:redeemed_at => Time.now, :order_id => order.id)
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

