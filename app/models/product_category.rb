class ProductCategory < ActiveRecord::Base
  include IslayShop::Statuses
  include Islay::Searchable

  search_terms :against => {:name => 'A'}

  extend FriendlyId
  friendly_id :name, :use => :slugged

  has_many    :products
  belongs_to  :image,     :class_name => 'ImageAsset',       :foreign_key => 'asset_id'
  belongs_to  :parent,    :class_name => 'ProductCategory',  :foreign_key => 'product_category_id'
  has_many    :children,  :class_name => 'ProductCategory',  :foreign_key => 'product_category_id'

  attr_accessible :name, :description, :asset_id, :product_category_id, :published, :status

  track_user_edits

  def self.published
    where(:published => true, :product_category_id => nil).order('position ASC')
  end

  # Returns all the ancestory categories in descending order
  #
  # TODO: Look at doing this at the DB level - important for deep hierarchies.
  #
  # @return Array of ProductCategories
  def parent_categories
    c = self
    categories = []
    until c.parent.blank? do
      c = c.parent
      categories.unshift c
    end
    categories
  end
end
