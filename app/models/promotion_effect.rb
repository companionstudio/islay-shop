class PromotionEffect < ActiveRecord::Base
  include Islay::PromotionConfig
  self.use_qualification = false
  self.use_apply = true

  belongs_to :promotion

  def apply!(order)
    config = self._options[option]
    config.apply!(self, order)
  end

  private

  def self.apply(method = nil, &blk)
    default_option.apply(method, &blk)
  end
end
