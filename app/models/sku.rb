class Sku < ActiveRecord::Base
  include IslayShop::MetaData
  include IslayShop::Statuses

  belongs_to :product
  has_many :sku_assets,                               :order => 'position ASC'
  has_many :assets, :through => :sku_assets,          :order => 'sku_assets.position ASC'
  has_many :stock_logs, :class_name => 'SkuStockLog', :order => 'created_at DESC'
  has_many :price_logs, :class_name => 'SkuPriceLog', :order => 'created_at DESC'

  attr_accessible :product_id, :description, :unit, :amount, :price, :stock_level, :published, :template, :position

  track_user_edits
  validations_from_schema

  attr_accessor :template

  # Summary of this SKU, which includes it's product name, data cols, sizing,
  # price etc.
  #
  # This should be over-ridden in any subclasses to be more specific.
  def desc
    "#{product.name} - #{price}"
  end
end
