class Sku < ActiveRecord::Base
  include Islay::MetaData
  include IslayShop::Statuses
  include Islay::Publishable
  include SkuDescription
  include Sku::PricePoints
  include Sku::StockManagement

  include PgSearch
  multisearchable :against => [:name, :metadata]

  belongs_to :product

  has_many :order_items

  has_many   :sku_assets,                          :order => 'position ASC'
  has_many   :assets,     :through => :sku_assets, :order => 'position ASC'
  has_many   :images,     :through => :sku_assets, :order => 'position ASC', :source => :asset, :class_name => 'ImageAsset'
  has_many   :audio,      :through => :sku_assets, :order => 'position ASC', :source => :asset, :class_name => 'AudioAsset'
  has_many   :videos,     :through => :sku_assets, :order => 'position ASC', :source => :asset, :class_name => 'VideoAsset'
  has_many   :documents,  :through => :sku_assets, :order => 'position ASC', :source => :asset, :class_name => 'DocumentAsset'

  positioned :product_id

  if defined?(::IslayBlog)
    attr_accessible :blog_entry_ids
    has_many :sku_blog_entries
    has_many :blog_entries, :through => :sku_blog_entries, :order => 'published_at DESC' do
      # Filters the blog entries by tag.
      #
      # @param String tag
      #
      # @return Array<BlogEntry>
      def tagged(tag)
        where([%{
          ? IN (
            SELECT LOWER(blog_tags.name) FROM blog_taggings
            JOIN blog_tags ON blog_tags.id = blog_taggings.blog_tag_id
            WHERE blog_entry_id = blog_entries.id
          )
        }, tag.downcase])
      end
    end
  end

  attr_accessible(
    :product_id, :description, :unit, :amount, :stock_level, :status,
    :published, :template, :position, :name, :weight, :volume, :size,
    :purchase_limiting, :purchase_limit, :asset_ids
  )

  track_user_edits

  validations_from_schema
  validates_presence_of :purchase_limit, :if => :purchase_limiting?, :message => "required when limiting is on"
  before_validation :calculate_short_desc

  attr_accessor :template

  # Checks to see if there are any SKUs which are low, or below the stock
  # alert level — which is looked up via the shop settings.
  #
  # @return Array<Sku>
  def self.alerts
    Sku.summarize_product.filter('saleable').where(["stock_level <= ?", Settings.for(:shop, :alert_level)]).order('stock_level')
  end

  # Produces a scope with calculated fields for stock alerts, updater_name etc.
  #
  # @return ActiveRecord::Relation
  def self.summary
    select(%{
      skus.*,
      (SELECT name FROM users WHERE id = updater_id) AS updater_name
    })
  end

  # Creates a scope which selects the SKU columns and the product name.
  #
  # @return ActiveRecord::Relation
  def self.summarize_product
    select("skus.*, products.name AS product_name").joins(:product)
  end

  # Creates a scope which only returns published products. The rules dictating
  # published are:
  #
  # - Sku is published
  # - It's product is published
  # - Product's category and all parent categories are published
  #
  # @return ActiveRecord::Relation
  def self.published
    where(%{
      skus.published = true
      AND products.published = true
      AND NOT EXISTS (
         SELECT 1 FROM product_categories AS pcs
         WHERE pcs.path @> product_categories.path AND pcs.published = false
      )
    }).joins(:product => :category)
  end

  # Creates a relation which only has the short_desc and ID.
  #
  # @return ActiveRecord::Relation
  def self.short_desc_only
    select('skus.id, skus.short_desc')
  end

  # Produces a scope with calculated fields like the ::summary method, but with
  # the addition of the product name.
  #
  # @return ActiveRecord::Relation
  def self.full_summary
    select(%{
      skus.*,
      (SELECT name FROM users WHERE id = skus.updater_id) AS updater_name,
      products.name AS product_name,
      CASE
        WHEN skus.status = 'for_sale' AND products.status = 'for_sale' THEN 'for_sale'
        WHEN products.status = 'discontinued' OR skus.status = 'discontinued' THEN 'discontinued'
        WHEN products.status = 'not_for_sale' OR skus.status = 'not_for_sale' THEN 'not_for_sale'
        ELSE skus.status
      END AS normalized_status
    }).joins(:product)
  end

  def self.filter(f)
    case f
    when 'discontinued', 'not_for_sale'
      where(["products.status = ? or skus.status = ?", f, f]).joins(:product)
    when 'all'
      scoped
    when 'saleable'
      where(%{
        skus.status = 'for_sale' AND skus.published = true
        AND products.status = 'for_sale' AND products.published = true
      }).joins(:product)
    else
      where("skus.status = 'for_sale' AND products.status = 'for_sale'").joins(:product)
    end
  end

  def self.sorted(s)
    if s
      order(s)
    else
      order('product_name ASC, skus.name ASC')
    end
  end

  # Returns the options required for generating a URL to this model. This is
  # currently used with searches.
  #
  # @return Hash
  def searchable_url_opts
    [:edit, product, self]
  end

  # A more readble name to be used when displaying search results.
  #
  # @return String
  def searchable_name
    "#{product.name} - #{short_desc}"
  end

  # Returns a collection of promotions that are related to the Sku. It
  # leans on the Promotions::Relevance module to do most of the work. The
  # resulting object has a bunch of methods for inspecting the results. See the
  # docs for Promotions::Relevance::Results.
  #
  # @return Promotions::Relevance::Results
  def related_promotions
    @related_promotions ||= Promotions::Relevance.to_sku(self)
  end

  # Checks to see if there are any promotions related to this record. See
  # #related_promotions for more detail.
  #
  # @return [true, false]
  def related_promotions?
    !related_promotions.empty?
  end

  # Indicates if this record can be destroyed. If this SKU has been used in an
  # order, it cannot be destroyed, since that would break historical records.
  #
  # @return Boolean
  #
  # @todo Have this account for promotions which also use this SKU.
  def destroyable?
    order_items.empty?
  end

  # Like the regular publish check, except it also goes looking for the
  # published status against the product.
  #
  # @return Boolean
  def normalized_published?
    if self[:normalized_published]
      normalized_published == true
    else
      product.published? and published?
    end
  end

  # Normalized for sale is like the regular for sale, but it also uses the
  # status of the product — if available — to figure out if it's actually, really
  # for real, for sale.
  #
  # @return Boolean
  def normalized_for_sale?
    if self[:normalized_status]
      normalized_status == 'for_sale'
    else
      product.status == 'for_sale' and status == 'for_sale'
    end
  end

  # Indicates if the SKU is available for sale.
  #
  # @return [true, false]
  def for_sale?
    status == 'for_sale'
  end

  # Checks to see if there is any stock at all
  #
  # @return [true, false]
  def in_stock?
    stock_level > 0
  end

  # Checks to see if there is sufficient stock to make a sale.
  #
  # @return [true, false]
  def sufficient_stock?(n)
    stock_level >= n
  end

  #The reverse of sufficient_stock?
  def insufficient_stock?(n)
    !sufficient_stock?(n)
  end

  class InsufficientStock < StandardError
    def initialize(sku)
      @sku = sku
    end

    def to_s
      "SKU ##{@sku.id} has insufficent stock"
    end
  end

  private

  # Calculates the description for a SKU. Should be over-ridden for a specific
  # app, or for a specific sub-class.
  #
  # @return String
  def calculate_short_desc
    if name_changed? or size_changed? or weight_changed? or volume_changed?
      self[:short_desc] = [].tap do |o|
        o << name if name?
        o << size if size?
        o << formatted_weight if weight?
        o << formatted_volume if volume?
      end.join(' - ')
    end
  end

  check_for_extensions
end
