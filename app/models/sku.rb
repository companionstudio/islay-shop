class Sku < ActiveRecord::Base
  belongs_to :product
  has_many :sku_assets,                       :order => 'position ASC'
  has_many :assets, :through => :sku_assets,  :order => 'sku_assets.position ASC'
  has_many :stock_logs, :class_name => 'SkuStockLog', :order => 'created_at DESC'
  has_many :price_logs, :class_name => 'SkuPriceLog', :order => 'created_at DESC'

  attr_accessible :product_id, :description, :unit, :amount, :price, :stock_level

  track_user_edits
end
