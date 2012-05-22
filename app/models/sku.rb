class Sku < ActiveRecord::Base
  belongs_to :product
  has_many :sku_assets
  has_many :assets, :through => :sku_assets

  attr_accessible :product_id, :description, :unit, :amount, :price, :stock_level

  track_user_edits
end
