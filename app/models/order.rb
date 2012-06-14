class Order < ActiveRecord::Base
  belongs_to  :person
  belongs_to  :promotion
  has_many    :items, :class_name => 'OrderItem'
  has_one     :credit_card_payment

  before_save :calculate_totals

  track_user_edits

  private

  def calculate_totals
    self.product_total = items.map(&:total).sum
    self.total = product_total + shipping_total
  end
end
