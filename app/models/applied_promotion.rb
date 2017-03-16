class AppliedPromotion < ActiveRecord::Base
  belongs_to :promotion
  belongs_to :order
  belongs_to :promotion_code
end
