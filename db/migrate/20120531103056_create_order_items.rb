class CreateOrderItems < ActiveRecord::Migration
  def change
    create_table :order_items do |t|
      t.integer :order_id,      :null => false, :on_delete => :cascade
      t.integer :sku_id,        :null => false
      t.string  :type,          :null => false, :limit => 15, :default => 'OrderRegularItem'
      t.integer :quantity,      :null => false, :limit => 3
      t.integer :actual_price,  :null => false, :precision => 7,  :scale => 2
      t.integer :actual_total,  :null => false, :precision => 7,  :scale => 2
      t.integer :discount,      :null => false, :precision => 7,  :scale => 2, :default => 0
      t.integer :price,         :null => false, :precision => 7,  :scale => 2
      t.integer :total,         :null => false, :precision => 7,  :scale => 2

      t.timestamps
    end
  end
end
