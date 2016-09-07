class AppliedPromotion < ActiveRecord::Base
  belongs_to :promotion
  belongs_to :order

  schema_validations except: :order
end
