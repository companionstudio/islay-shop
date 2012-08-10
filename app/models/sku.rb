class Sku < ActiveRecord::Base
  include IslayShop::MetaData
  include IslayShop::Statuses
  include SkuDescription

  belongs_to :product
  has_many :sku_assets,                               :order => 'position ASC'
  has_many :assets, :through => :sku_assets,          :order => 'sku_assets.position ASC'
  has_many :stock_logs, :class_name => 'SkuStockLog', :order => 'created_at DESC'
  has_many :price_logs, :class_name => 'SkuPriceLog', :order => 'created_at DESC'

  attr_accessible(
    :product_id, :description, :unit, :amount, :price, :stock_level,
    :published, :template, :position, :name, :weight, :volume, :size
  )

  track_user_edits
  validations_from_schema

  before_save :log_price

  attr_accessor :template

  # Produces a scope with calculated fields for stock alerts, updater_name etc.
  #
  # @return ActiveRecord::Relation
  def self.summary
    select(%{
      skus.*,
      (SELECT name FROM users WHERE id = updater_id) AS updater_name
    })
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

      sku.stock_logs.build(:before => sku.stock_level, :after => result, :action => action)
      sku.stock_level = result
      sku.save!
    end

    skus
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

  # Checks to see if the price has changed and if it has, creates a log.
  def log_price
    if price_changed?
    logger.debug "DO A THOINK!"
      price_logs.build(:before => price_was, :after => price)
    end
  end
end
