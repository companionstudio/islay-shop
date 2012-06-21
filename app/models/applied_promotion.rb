class AppliedPromotion < ActiveRecord::Base
  belongs_to :promotion
  belongs_to :order
  belongs_to :qualifying_item, :class_name => "OrderRegularItem", :foreign_key => 'qualifying_order_item_id'
  belongs_to :bonus_item,      :class_name => "OrderBonusItem",   :foreign_key => 'bonus_order_item_id'

  attr_accessible :promotion, :order, :qualifying_item, :bonus_item
end
