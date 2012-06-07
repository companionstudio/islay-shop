class PromotionCondition < ActiveRecord::Base
  include Islay::PromotionConfig

  belongs_to :promotion

  # Check to see if the order qualifies for this particular condition.
  def qualifies?(order)
    config = self._options[option]
    config.qualifies?(self, order)
  end

  private

  def self.qualification(method = nil, &blk)
    default_option.qualification(method, &blk)
  end
end
