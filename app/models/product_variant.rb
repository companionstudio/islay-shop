class ProductVariant < ActiveRecord::Base
  include Islay::MetaData

  belongs_to  :product
  has_many    :skus,                                        -> {order('position ASC')}
  has_many    :product_variant_assets,                      -> {order('position ASC')}
  has_many    :assets,                                      -> {order('position ASC')}, :through => :product_variant_assets
end
