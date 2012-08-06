class CreateSkuPriceLogs < ActiveRecord::Migration
  def change
    create_table :sku_price_logs do |t|
      t.integer :sku_id,  :null => false,   :on_delete => :cascade
      t.float   :before,  :null => false,   :limit => 5
      t.float   :after,   :null => false,   :limit => 5

      t.user_tracking
      t.timestamps
    end
  end
end
