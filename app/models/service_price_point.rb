class ServicePricePoint < ActiveRecord::Base
  extend SpookAndPuff::MoneyAttributes
  attr_money :price
  belongs_to :service
  has_many   :order_items, :class_name => "OrderServiceItem"
  track_user_edits
end
