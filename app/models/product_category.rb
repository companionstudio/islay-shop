class ProductCategory < ActiveRecord::Base
  include IslayShop::Statuses
  include Islay::Searchable

  search_terms :against => {:name => 'A'}

  extend FriendlyId
  friendly_id :name, :use => :slugged
  positioning :product_category

  has_many    :products, :order => 'products.position'
  belongs_to  :image,     :class_name => 'ImageAsset',       :foreign_key => 'asset_id'
  belongs_to  :parent,    :class_name => 'ProductCategory',  :foreign_key => 'product_category_id'
  has_many    :children,  :class_name => 'ProductCategory',  :foreign_key => 'product_category_id', :order => 'position'

  attr_accessible(
    :name, :description, :asset_id, :product_category_id, :published, :status,
    :position
  )

  track_user_edits

  def self.published
    where(:published => true, :product_category_id => nil).order('product_categories.position ASC')
  end

  # Checks to see if the category has either products of categories assigned to
  # it. If it is empty, this means the users can start assigning either — but
  # not both — to it.
  #
  # @return Boolean
  def empty?
    products.empty? and children.empty?
  end

  # Checks to see if this category has products assigned to it, in which case
  # it cannot have other categories added to it.
  #
  # @return Boolean
  def products?
    !products.empty?
  end

  # Checks for any child categories.
  #
  # @return Boolean
  def children?
    !children.empty?
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
