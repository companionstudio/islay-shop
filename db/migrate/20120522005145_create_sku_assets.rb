class CreateSkuAssets < ActiveRecord::Migration
  def change
    create_table :sku_assets do |t|
      t.integer :sku_id,    :null => false, :on_delete => :cascade
      t.integer :asset_id,  :null => false, :on_delete => :cascade
      t.integer :position,  :null => false, :limit => 3, :default => 1

      t.timestamps
    end
  end
end
