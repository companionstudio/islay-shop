class CreateSkuPriceLogs < ActiveRecord::Migration[4.2]
  def change
    create_table :sku_price_logs do |t|
      t.integer :sku_id,  :null => false,   :on_delete => :cascade
      t.float   :price_before,        :null => true,   :limit => 5
      t.float   :price_after,         :null => true,   :limit => 5

      t.integer :batch_size_before,   :null => true,    :limit => 5
      t.integer :batch_size_after,    :null => true,    :limit => 5

      t.float   :batch_price_before,  :null => true,   :limit => 5
      t.float   :batch_price_after,   :null => true,   :limit => 5

      t.user_tracking(true)
      t.timestamps
    end
  end
end
