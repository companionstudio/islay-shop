class ProductCategory < ActiveRecord::Base
  has_many    :products
  belongs_to  :image,     :class_name => 'ImageAsset',       :foreign_key => 'asset_id'
  belongs_to  :parent,    :class_name => 'ProductCategory',  :foreign_key => 'product_category_id'
  has_many    :children,  :class_name => 'ProductCategory',  :foreign_key => 'product_category_id'

  attr_accessible :name, :description, :asset_id, :product_category_id, :published

  track_user_edits
end
