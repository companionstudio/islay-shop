class ProductVariantAsset < ActiveRecord::Base
  belongs_to :product_variant
  belongs_to :asset
end
