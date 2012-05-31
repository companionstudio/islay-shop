class OrderItem < ActiveRecord::Base
  belongs_to :promotion
  belongs_to :order
  belongs_to :sku
end
