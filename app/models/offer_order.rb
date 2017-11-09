class OfferOrder < ActiveRecord::Base
  belongs_to :offer
  belongs_to :order
end
