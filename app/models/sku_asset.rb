class SkuAsset < ActiveRecord::Base
  belongs_to :sku
  belongs_to :asset
end
