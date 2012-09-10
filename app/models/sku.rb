class Sku < ActiveRecord::Base
  include IslayShop::MetaData
  include IslayShop::Statuses
  include SkuDescription

  belongs_to :product
  has_many :sku_assets,                               :order => 'position ASC'
  has_many :assets, :through => :sku_assets,          :order => 'sku_assets.position ASC'
  has_many :stock_logs, :class_name => 'SkuStockLog', :order => 'created_at DESC'
  has_many :price_logs, :class_name => 'SkuPriceLog', :order => 'created_at DESC'
  has_many :order_items

  positioning :product_id

  if Islay::Engine.config.integrate_shop_and_blog
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
    :product_id, :description, :unit, :amount, :price, :stock_level, :status,
    :published, :template, :position, :name, :weight, :volume, :size,
    :batch_size, :batch_price, :purchase_limiting, :purchase_limit, :asset_ids
  )

  track_user_edits

  validations_from_schema
  validate :batch_size_and_pricing
  validates_presence_of :purchase_limit, :if => :purchase_limiting?, :message => "required when limiting is on"

  before_update :log_price

  attr_accessor :template

  # Checks to see if there are any SKUs which are low, or below the stock
  # alert level — which is looked up via the shop settings.
  #
  # @return Array<Sku>
  def self.alerts
    Sku.summarize_product.filter('for_sale').where(["stock_level <= ?", Settings.for(:shop, :alert_level)]).order('stock_level')
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
    select(%{
      skus.*,
      (SELECT name FROM products WHERE products.id = product_id) AS product_name
    })
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

  # Move the stock level down for the specified SKUs. Log each modification
  # as a purchase action.
  #
  # @param Hash skus
  #
  # @return Hash
  def self.purchase_stock!(skus)
    modify_stock_level!('purchase', skus) do |sku, amount|
      sku.stock_level - amount
    end
  end

  # Move the stock level up for the specified SKUs. Log each modification
  # as a return action; when an order is cancelled/refunded.
  #
  # @param Hash skus
  #
  # @return Hash
  def self.return_stock!(skus)
    modify_stock_level!('return', skus) do |sku, amount|
      sku.stock_level + amount
    end
  end

  # Updates the stock levels and flags them as restocks or adjust down as
  # appropriate.
  #
  #
  # @param Hash skus
  #
  # @return nil
  def self.update_stock!(skus)
    skus = skus.reduce({}) do |acc, e|
      acc[e[0].to_i] = e[1].to_i
      acc
    end

    levels = select('id, stock_level').where(:id => skus.keys).reduce({}) do |acc, e|
      acc[e.id] = e.stock_level
      acc
    end

    restocks  = skus.select {|id, level| level > levels[id]}
    adjusts   = skus.select {|id, level| level < levels[id]}

    unless restocks.empty?
      modify_stock_level!('restock', restocks) {|sku, amount| amount}
    end

    unless adjusts.empty?
      modify_stock_level!('adjust_down', adjusts) {|sku, amount| amount}
    end

    nil
  end

  # Move the stock level up for the specified SKUs. Log each modification
  # as a restock.
  #
  # @param Hash skus
  #
  # @return Hash
  def self.increment_stock!(skus)
    modify_stock_level!('restock', skus) do |sku, amount|
      sku.stock_level + amount
    end
  end

  # Move the stock level adjustment for the specified SKUs. Log each modification
  # as a adjust_down.
  #
  # @param Hash skus
  #
  # @return Hash
  def self.increment_stock!(skus)
    modify_stock_level!('adjust_down', skus) do |sku, amount|
      sku.stock_level - amount
    end
  end

  # Modifies the stock level for the specified SKUs and logs the modification
  # with the action. The block is run for each SKU identified and the result
  # is used as the new stock level.
  #
  # @param String action
  # @param Hash skus
  # @param Block blk
  #
  # @return Hash
  def self.modify_stock_level!(action, skus, &blk)
    skus.each_pair do |id, amount|
      sku     = find(id)
      result  = blk.call(sku, amount)

      raise InsufficientStock.new(sku) if result < 0

      sku.stock_logs.build(:before => sku.stock_level || 0, :after => result, :action => action)
      sku.stock_level = result
      sku.save!
    end

    skus
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

  # Indicates if this SKU has any batch pricing specified.
  #
  # @return Boolean
  def batch_pricing?
    batch_price? and batch_size?
  end

  # Indicates if the SKU has any stock.
  #
  # @return [Boolean]
  def in_stock?
    stock_level > 0
  end

  # Indicates if the SKU is out of stock.
  #
  # @return [Boolean]
  def out_of_stock?
    stock_level < 1
  end

  # Indicates if the SKU's stock level is getting low; on or below the
  # configured threshold.
  #
  # The threshold is set in the Settings class.
  #
  # @return Boolean
  def low_stock?
    stock_level <= Settings.for(:shop, :alert_level)
  end

  # Indicates if there is a stock warning for the SKU. The warning is only true
  # if the stock is for sale, published and low.
  #
  # @return Boolean
  def stock_warning?
    normalized_published? and normalized_for_sale? and low_stock?
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
  # @return Boolean
  def for_sale?
    status == 'for_sale'
  end

  # Returns a money formatted string of the price.
  #
  # @return String
  def formatted_price
    format_money(price)
  end

  # Returns a money formatted string of the batch price.
  #
  # @return String
  def formatted_batch_price
    format_money(batch_price)
  end

  # Formats a float into a monentary formatted string i.e. sticks a '$' in the
  # front and pads the decimals.
  #
  # @param Float value
  #
  # @return String
  def format_money(value)
    "$%.2f" % value
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

  # Both batch volume and pricing may be empty, but if one is present, then
  # both must be filled in.
  def batch_size_and_pricing
    if batch_size? and !batch_price?
      errors.add(:batch_price, "can't be missing when setting batch size")
    elsif batch_price? and !batch_size?
      errors.add(:batch_size, "can't be missing when setting batch price")
    end
  end

  # Checks to see if the price has changed and if it has, creates a log.
  def log_price
    if price_changed? or batch_size_changed? or batch_price_changed?
      log = price_logs.build(
        :price_before       => price_was || 0,
        :price_after        => price,
        :batch_size_before  => batch_size_was,
        :batch_size_after   => batch_size,
        :batch_price_before => batch_price_was,
        :batch_price_after  => batch_price
      )
    end
  end

  check_for_extensions
end
