class CreateOrderItemAdjustments < ActiveRecord::Migration
  def change
    create_table :order_item_adjustments do |t|
      t.integer :order_item_id, :null => false, :on_delete => :cascade
      t.string  :kind,          :null => false # enum: bonus, item_adjustment, order_adjustment
      t.string  :source,        :null => false # enum: promotion, manual
      t.integer :quantity,      :null => false
      t.decimal :adjustment,    :null => false, :default => 0, :precision => 14, :scale => 7
    end
  end
end
