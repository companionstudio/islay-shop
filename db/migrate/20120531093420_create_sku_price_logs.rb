class CreateSkuPriceLogs < ActiveRecord::Migration
  def change
    create_table :sku_price_logs do |t|
      t.integer :sku_id,  :null => false,   :on_delete => :cascade
      t.integer :before,  :null => false,   :limit => 5
      t.integer :after,   :null => false,   :limit => 5

      t.user_tracking
      t.timestamps
    end
  end
end
