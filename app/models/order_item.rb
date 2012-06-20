class OrderItem < ActiveRecord::Base
  belongs_to :promotion
  belongs_to :order
  belongs_to :sku

  before_validation :store_actual_price_and_total, :store_price_and_total

  attr_accessible :sku_id, :quantity

  private

  def store_actual_price_and_total
    self.actual_price = sku.price
    self.actual_total = sku.price * quantity
  end

  def store_price_and_total
    self.price = actual_price if price.blank?
    self.total = actual_total if total.blank?
  end
end
