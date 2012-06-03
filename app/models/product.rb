class Product < ActiveRecord::Base
  include IslayShop::MetaData
  include IslayShop::Statuses

  belongs_to :category, :class_name => 'ProductCategory', :foreign_key => 'product_category_id'
  belongs_to :range,    :class_name => 'ProductRange',    :foreign_key => 'product_range_id'
  has_many   :product_assets
  has_many   :assets,   :through => :product_assets
  has_many   :skus, :order => 'position ASC'
  has_many   :sku_assets, :through => :skus, :through => :assets
  has_many   :variants, :class_name => 'ProductVariant', :order => 'position ASC'

  attr_accessible :name, :description, :product_category_id, :product_range_id, :published, :status, :skus_attributes

  track_user_edits

  accepts_nested_attributes_for :skus, :allow_destroy => true, :reject_if => :new_sku?
  validates_associated :skus

  private

  def new_sku?(params)
    is_new = params.delete(:template) == "true"
  end
end
