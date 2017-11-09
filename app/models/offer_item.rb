class OfferItem < ActiveRecord::Base
  belongs_to :offer
  belongs_to :sku
end
