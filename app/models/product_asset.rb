class ProductAsset < ActiveRecord::Base
  belongs_to :product
  belongs_to :asset
  # attr_accessible :position
end
