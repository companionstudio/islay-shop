class CreateOrderItems < ActiveRecord::Migration
  def change
    create_table :order_items do |t|
      t.integer :order_id,  :null => false, :on_delete => :cascade
      t.integer :sku_id,    :null => false
      t.integer :quantity,  :null => false, :limit => 3
      t.integer :price,     :null => false, :precision => 7,  :scale => 2

      t.timestamps
    end
  end
end
