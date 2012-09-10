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
  validations_from_schema

  # Creates a scope for published categories.
  #
  # @return ActiveRecord::Relation
  def self.published
    where(:published => true, :product_category_id => nil).order('product_categories.position ASC')
  end

  # Creates a scope for categories without any products.
  #
  # @return ActiveRecord::Relation
  def self.no_products
    where("NOT EXISTS (SELECT 1 FROM products WHERE product_category_id = product_categories.id)")
  end

  # Creates a scope which only finds top level categories i.e. those without
  # parents. Can optionally take a slug, which will also be excluded.
  #
  # @param String slug
  #
  # @return ActiveRecord::Relation
  def self.top_level(slug = nil)
    if slug.nil?
      where("product_category_id IS NULL")
    else
      where("product_category_id IS NULL AND slug != ?", slug)
    end
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
