class OrderItem < ActiveRecord::Base
  belongs_to :promotion
  belongs_to :order
  belongs_to :sku

  before_validation :store_actual_price_and_total, :store_price_and_total

  attr_accessible :sku_id, :quantity

  # Used to count the total number of individual SKUs. Most useful when called
  # via an association. In fact, that's probably the only time you should use it.
  #
  # @return ActiveRecord::Relation
  def self.sku_total_quantity
    sum(:quantity)
  end

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
