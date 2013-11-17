class AppliedPromotion < ActiveRecord::Base
  belongs_to :promotion
  belongs_to :order

  attr_accessible :promotion, :order
end
