class CreateSkus < ActiveRecord::Migration
  def change
    create_table :skus do |t|
      t.integer     :product_id,          :null => false, :on_delete => :cascade
      t.integer     :product_variant_id,  :null => true,  :on_delete => :set_null
      t.integer     :position,            :null => false, :limit => 3, :default => 1
      t.string      :name,                :null => true,  :limit => 200
      t.integer     :weight,              :null => true,  :limit => 10
      t.integer     :volume,              :null => true,  :limit => 10
      t.string      :size,                :null => true,  :limit => 50
      t.hstore      :metadata,            :null => true
      t.float       :price,               :null => false, :precision => 7, :scale => 2
      t.integer     :batch_size,          :null => true,  :limit => 5
      t.float       :batch_price,         :null => true,  :precision => 7, :scale => 2
      t.integer     :stock_level,         :null => false, :limit => 5, :default => 1
      t.string      :status,              :null => false, :limit => 20, :default => 'for_sale'
      t.boolean     :purchase_limiting,   :null => false, :default => false
      t.integer     :purchase_limit,      :null => true,  :limit => 5

      t.publishing
      t.user_tracking
      t.timestamps
    end
  end
end
