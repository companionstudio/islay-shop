class CreateOrderItems < ActiveRecord::Migration
  def change
    create_table :order_items do |t|
      t.integer :order_id,      :null => false, :on_delete => :cascade
      t.integer :sku_id,        :null => false
      t.integer :quantity,      :null => false, :limit => 3
      t.boolean :bonus,         :null => false, :default => false
      t.float   :discount,      :null => false, :precision => 7,  :scale => 2, :default => 0
      t.float   :actual_price,  :null => false, :precision => 7,  :scale => 2
      t.float   :actual_total,  :null => false, :precision => 7,  :scale => 2
      t.float   :price,         :null => false, :precision => 7,  :scale => 2
      t.float   :total,         :null => false, :precision => 7,  :scale => 2

      t.timestamps
    end
  end
end
