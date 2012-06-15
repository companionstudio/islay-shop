class Order < ActiveRecord::Base
  belongs_to  :person
  belongs_to  :promotion
  has_many    :items, :class_name => 'OrderItem'
  has_one     :credit_card_payment

  before_save :calculate_totals

  track_user_edits

  def item_map
    @item_map ||= items.inject({}) {|h, i| h[i.sku_id] = i; h}
  end

  def add_item(sku_id, quantity = 1)
    update_item(sku_id.to_i, quantity.to_i, true)
  end

  def update_item(sku_id, quantity, add = false)
    sku = Sku.find(sku_id)
    item = item_map[sku_id]

    total = if item
      add ? item.quantity + quantity : quantity
    else
      quantity
    end

    item = item_map[sku_id] = items.build(:sku_id => sku_id) unless item
    item.quantity = total
  end

  private

  def calculate_totals
    self.product_total = items.map(&:total).sum
    self.total = product_total + shipping_total
  end
end
