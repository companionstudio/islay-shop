class ProductCategory < ActiveRecord::Base
  include IslayShop::Statuses
  include Islay::Searchable

  search_terms :against => {:name => 'A'}

  extend FriendlyId
  friendly_id :name, :use => :slugged
  positioning :product_category

  has_many    :products, :order => 'position'
  belongs_to  :image,     :class_name => 'ImageAsset',       :foreign_key => 'asset_id'
  belongs_to  :parent,    :class_name => 'ProductCategory',  :foreign_key => 'product_category_id'
  has_many    :children,  :class_name => 'ProductCategory',  :foreign_key => 'product_category_id', :order => 'position'

  attr_accessible(
    :name, :description, :asset_id, :product_category_id, :published, :status,
    :position
  )

  track_user_edits

  def self.published
    where(:published => true, :product_category_id => nil).order('position ASC')
  end
end
