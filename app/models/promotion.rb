class Promotion < ActiveRecord::Base
  has_many :orders
  has_many :order_items
end
