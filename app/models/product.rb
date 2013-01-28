class Product < ActiveRecord::Base
  include Islay::MetaData
  include IslayShop::Statuses
  include Islay::Publishable
  include Islay::Searchable

  search_terms :against => {:name => 'A'}

  extend FriendlyId
  friendly_id :name, :use => :slugged

  positioned :product_category_id

  belongs_to :category, :class_name => 'ProductCategory', :foreign_key => 'product_category_id'
  belongs_to :range,    :class_name => 'ProductRange',    :foreign_key => 'product_range_id'
  has_many   :skus, :order => 'position ASC'
  has_many   :sku_assets, :through => :skus, :through => :assets
  has_many   :variants, :class_name => 'ProductVariant', :order => 'position ASC'
  has_many   :stock_logs, :through => :skus, :order => 'created_at DESC'
  has_many   :price_logs, :through => :skus, :order => 'created_at DESC'

  has_many   :product_assets
  has_many   :assets,     :through => :product_assets, :order => 'position ASC'
  has_many   :images,     :through => :product_assets, :order => 'position ASC', :source => :asset, :class_name => 'ImageAsset'
  has_many   :audio,      :through => :product_assets, :order => 'position ASC', :source => :asset, :class_name => 'AudioAsset'
  has_many   :videos,     :through => :product_assets, :order => 'position ASC', :source => :asset, :class_name => 'VideoAsset'
  has_many   :documents,  :through => :product_assets, :order => 'position ASC', :source => :asset, :class_name => 'DocumentAsset'


  attr_accessible(
    :name, :description, :product_category_id, :product_range_id, :published,
    :status, :skus_attributes, :asset_ids, :position
  )

  track_user_edits
  validations_from_schema

  before_save :store_published_at

  # Returns an arrary with information sufficient to arrange the products and
  # their parent categories into a tree.
  #
  # @return Array<ActiveRecord::Base>
  def self.tree
    find_by_sql(%{
      WITH categories AS (
        SELECT
          id,
          name,
          true AS disabled,
          position,
          NLEVEL(path) AS depth,
          CASE
            WHEN NLEVEL(path) = 0 THEN id
            ELSE LTREE2TEXT(SUBPATH(path, -1, 1))::integer
          END AS parent_id
        FROM product_categories
        WHERE (
          EXISTS (SELECT 1 FROM products WHERE product_category_id = product_categories.id)
          OR
          EXISTS (
            SELECT 1 FROM product_categories AS children
            WHERE children.path <@ text2ltree(product_categories.id::text)
            AND EXISTS (SELECT 1 FROM products WHERE product_category_id = children.id)
          )
        )
      ) 

      SELECT * FROM (
        SELECT 
          products.id, 
          products.name, 
          false AS disabled,
          products.position,
          categories.depth + 1 AS depth,
          product_category_id AS parent_id 
        FROM products
        JOIN categories ON categories.id = products.product_category_id

        UNION ALL

        SELECT NULL AS id, name, disabled, position, depth, parent_id
        FROM categories
      ) AS results ORDER BY parent_id, depth, position
    })
  end

  def self.newest
    where(:published => true).order('published_at DESC').limit(4)
  end

  def self.published
    where(:published => true).order('name ASC')
  end

  # Creates a scope where the returned fields are limited and extra calculated
  # fields like a SKU summary have been added.
  def self.summary
    select(%{
      id, slug, published, status, name, updated_at,
      (SELECT name FROM users WHERE id = updater_id) AS updater_name,
      (SELECT ARRAY_TO_STRING(ARRAY_AGG(short_desc), ', ')
       FROM skus
       GROUP BY product_id HAVING product_id = products.id) AS skus_summary,
      CASE
        WHEN published = false OR status != 'for_sale' THEN 'na'
        WHEN (
          EXISTS (SELECT 1 FROM skus WHERE product_id = products.id AND published = true AND status = 'for_sale' AND stock_level = 0)
        ) THEN 'warning'
        WHEN (
          EXISTS (SELECT 1 FROM skus WHERE product_id = products.id AND published = true AND status = 'for_sale' AND stock_level <= 5)
        ) THEN 'low'
        ELSE 'ok'
      END AS stock_level_notice
    })
  end

  def self.filtered(f)
    if f
      where :published => case f
      when 'published' then true
      when 'unpublished' then false
      end
    else
      scoped
    end
  end

  def self.sorted(s)
    if s
      order(s)
    else
      order(:name)
    end
  end

  # Check to see if any of the SKUs attached to this product are in stock.
  #
  # @return Boolean
  def in_stock?
    skus.map {|s| s.stock_level > 0}.any?
  end

  def stock_warning?
    !in_stock? or stock_low?
  end

  def stock_low?
    false
  end

  def stock_level_status
    if !in_stock?
      'out'
    elsif stock_low?
      'low'
    else
      'ok'
    end
  end

  def friendly_stock_level_status
    'OK'
  end

  def for_sale?
    status == 'for_sale'
  end

  def destroyable?
    true
  end

  # Indicates if the product has it's status set to discontinued.
  #
  # @return Boolean
  def discontinued?
    status == 'discontinued'
  end

  # Returns all the ancestory categories for this product in descending order
  #
  # TODO: Look at doing this at the DB level - important for deep hierarchies.
  #
  # @return Array of ProductCategories
  def parent_categories
    c = category
    categories = [c]
    until c.parent.blank? do
      c = c.parent
      categories.unshift c
    end
    categories
  end

  private

  def store_published_at
    if published and published_at.blank?
      self.published_at = Time.now
    end
  end

  def new_sku?(params)
    params.delete(:template) == "true"
  end

  check_for_extensions
end
