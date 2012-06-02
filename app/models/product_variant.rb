class ProductVariant < ActiveRecord::Base
  include IslayShop::MetaData

  belongs_to  :product
  has_many    :skus,                                        :order => 'position ASC'
  has_many    :product_variant_assets,                      :order => 'position ASC'
  has_many    :assets, :through => :product_variant_assets, :order => 'position ASC'
end
