class OrderItem < ActiveRecord::Base
  belongs_to :promotion
  belongs_to :order
  belongs_to :sku

  before_validation :store_price

  attr_accessible :sku_id, :quantity

  def total
    quantity * price
  end

  private

  def store_price
    self.price = sku.price
  end
end
