class CreateOrderItems < ActiveRecord::Migration
  def change
    create_table :order_items do |t|
      t.integer :order_id,        :null => false, :on_delete => :cascade
      t.integer :sku_id,          :null => false
      t.integer :quantity,        :null => false, :limit => 3
      # Type is an enum consisting of: regular, discounted, batched, batched_and_discounted, bonus
      t.string  :type,            :null => false, :limit => 50, :default => 'regular'
      t.integer :batch_size,      :null => true,  :limit => 5
      t.float   :batch_price,     :null => true,  :precision => 7,  :scale => 2
      t.float   :original_price,  :null => false, :precision => 7,  :scale => 2
      t.float   :original_total,  :null => false, :precision => 7,  :scale => 2
      t.float   :discount,        :null => false, :precision => 7,  :scale => 2, :default => 0
      t.float   :adjusted_price,  :null => false, :precision => 7,  :scale => 2
      t.float   :total,           :null => false, :precision => 7,  :scale => 2

      t.timestamps
    end
  end
end
