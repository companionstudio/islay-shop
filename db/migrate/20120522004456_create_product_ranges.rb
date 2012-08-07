class CreateProductRanges < ActiveRecord::Migration
  def change
    create_table :product_ranges do |t|
      t.integer :asset_id,      :null => true
      t.string  :name,          :null => false, :limit => 255, :index => :unique
      t.string  :description,   :null => false, :limit => 4000

      t.publishing
      t.user_tracking
      t.timestamps
    end
  end
end
