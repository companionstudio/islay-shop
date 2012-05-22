class CreateProductAssets < ActiveRecord::Migration
  def change
    create_table :product_assets do |t|
      t.integer :product_id,  :null => false, :on_delete => :cascade
      t.integer :asset_id,    :null => false, :on_delete => :cascade
      t.integer :position,        :null => false, :limit => 3, :default => 1

      t.timestamps
    end
  end
end
