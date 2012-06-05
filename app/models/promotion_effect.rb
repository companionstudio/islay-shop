class PromotionEffect < ActiveRecord::Base
  belongs_to :promotion
  attr_accessible :config
end
