class SkuAsset < ActiveRecord::Base
  belongs_to :sku
  belongs_to :asset
  attr_accessible :position
end
