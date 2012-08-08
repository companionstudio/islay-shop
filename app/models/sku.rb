class Sku < ActiveRecord::Base
  include IslayShop::MetaData
  include IslayShop::Statuses

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

  attr_accessor :template

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

  # Summary of this SKU, which includes it's product name, data cols, sizing,
  # price etc.
  #
  # @return String
  #
  # @note This should be over-ridden in any subclasses to be more specific.
  def desc
    "#{product.name} - #{price}"
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

  class InsufficientStock < StandardError
    def initialize(sku)
      @sku = sku
    end

    def to_s
      "SKU ##{sku.id} has insufficent stock"
    end
  end
end
