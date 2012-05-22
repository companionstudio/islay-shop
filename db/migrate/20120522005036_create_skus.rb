class CreateSkus < ActiveRecord::Migration
  def change
    create_table :skus do |t|
      t.integer :product_id,      :null => false, :on_delete => :cascade
      t.integer :position,        :null => false, :limit => 3, :default => 1
      t.string  :description,     :null => true,  :limit => 200
      t.string  :unit,            :null => false, :limit => 5
      t.integer :amount,          :null => false, :limit => 5
      t.integer :price,           :null => false, :precision => 7, :scale => 2
      t.integer :stock_level,     :null => false, :limit => 5, :default => 1

      t.user_tracking
      t.timestamps
    end
  end
end
