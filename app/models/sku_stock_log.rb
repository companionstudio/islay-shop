class SkuStockLog < ActiveRecord::Base
  belongs_to :sku

  attr_accessible :before, :after, :action
end
