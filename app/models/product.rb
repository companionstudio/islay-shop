class Product < ActiveRecord::Base
  include IslayShop::MetaData

  belongs_to :category, :class_name => 'ProductCategory', :foreign_key => 'product_category_id'
  belongs_to :range,    :class_name => 'ProductRange',    :foreign_key => 'product_range_id'
  has_many   :product_assets
  has_many   :assets,   :through => :product_assets
  has_many   :skus
  has_many   :sku_assets, :through => :skus, :through => :assets
  has_many   :variants, :class_name => 'ProductVariant', :order => 'position ASC'

  attr_accessible :name, :description, :product_category_id, :product_range_id, :published, :status

  track_user_edits
end
