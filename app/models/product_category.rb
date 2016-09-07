class ProductCategory < ActiveRecord::Base
  include HierarchyConcern
  include IslayShop::Statuses

  extend FriendlyId
  friendly_id :name, :use => [:slugged, :finders]

  include PgSearch
  multisearchable :against => [:name, :description]

  positioned :path

  has_many    :products, -> {order('products.position')}
  belongs_to  :image,     :class_name => 'ImageAsset',       :foreign_key => 'asset_id'

  # attr_accessible(
  #   :name, :description, :asset_id, :product_category_id, :published, :status,
  #   :position
  # )

  track_user_edits

  # Returns a relation with information sufficient to arrange the categories
  # into a tree.
  #
  # @return ActiveRecord::Relation
  def self.tree
    select(%{
      id,
      name,
      NLEVEL(path) AS depth,
      CASE
        WHEN NLEVEL(path) = 0 THEN id
        ELSE LTREE2TEXT(SUBPATH(path, -1, 1))::integer
      END AS parent_id
    }).order("parent_id, depth, position")
  end

  # Returns a relation which restricts the the categories to those which
  # which could serve as a parent to another category.
  #
  # @param [String, Integer] id
  #
  # @return ActiveRecord::Relation
  def self.potential_parents(id = nil)
    w = where("NOT EXISTS (SELECT 1 FROM products WHERE product_category_id = product_categories.id)")
    id ? w.where("id != ?", id.to_i) : w
  end

  # Returns a relation which marks any categories that can be used as parents
  # for products.
  #
  # @return ActiveRecord::Relation
  def self.mark_disabled
    select(%{
      (EXISTS (
        SELECT 1 FROM product_categories AS pcs
        WHERE pcs.path <@ (product_categories.path || text2ltree(product_categories.id::text))
      )) AS disabled
    })
  end

  # Returns the ID of the parent category if there is one.
  #
  # @return [ProductCategory, nil]
  def product_category_id
    parent.id if parent
  end

  # Sets the parent category via it's ID. If ID is #blank? it does nothing.
  #
  # @param [Integer, String] id
  #
  # @return [ProductCategory, nil]
  def product_category_id=(id)
    self.parent = if id.blank?
      nil
    else
      ProductCategory.find(id)
    end
  end

  # Generates a select statement which summarises the state of the category.
  #
  # @return ActiveRecord::Relation
  def self.summary
    select(SUMMARY % Settings.for(:shop, :alert_level))
  end

  # Creates a scope for published categories.
  #
  # @param Boolean bool
  #
  # @return ActiveRecord::Relation
  def self.published(bool = true)
    where(:published => bool)
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
      where("path = ''")
    else
      where("path = '' AND slug != ?", slug)
    end
  end

  # Returns a collection of promotions that are related to the Category. It
  # leans on the Promotions::Relevance module to do most of the work. The
  # resulting object has a bunch of methods for inspecting the results. See the
  # docs for Promotions::Relevance::Results.
  #
  # @return Promotions::Relevance::Results
  def related_promotions
    @related_promotions ||= Promotions::Relevance.to_category(self)
  end

  # Checks to see if there are any promotions related to this record. See
  # #related_promotions for more detail.
  #
  # @return [true, false]
  def related_promotions?
    !related_promotions.empty?
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

  # The SQL fragment used to construct a summary select statement.
  SUMMARY = %{
     id, slug, path, name, status, published, updated_at,
    (SELECT name FROM users WHERE id = updater_id) AS updater_name,
    (EXISTS (
      SELECT 1 FROM product_categories AS cs
      WHERE cs.path = (product_categories.path || product_categories.id::text::ltree))
    ) AS is_parent,
    CASE
      WHEN (
        EXISTS (
          SELECT 1 FROM products AS ps
          JOIN skus ON product_category_id = product_categories.id
          AND ps.published = true AND ps.status = 'for_sale'
          AND skus.published = true AND skus.status = 'for_sale'
          AND product_id = ps.id AND stock_level = 0
        )
      ) THEN 'warning'
      WHEN (
        EXISTS (
          SELECT 1 FROM products AS ps
          JOIN skus ON product_category_id = product_categories.id AND product_id = ps.id
          AND ps.published = true AND ps.status = 'for_sale'
          AND skus.published = true AND skus.status = 'for_sale'
          AND stock_level <= %s
        )
      ) THEN 'low'
      ELSE 'ok'
    END AS stock_level
  }.freeze
end
