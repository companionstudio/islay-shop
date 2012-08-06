class CreateSkus < ActiveRecord::Migration
  def change
    create_table :skus do |t|
      t.integer     :product_id,          :null => false, :on_delete => :cascade
      t.integer     :product_variant_id,  :null => true, :on_delete => :set_null
      t.integer     :position,            :null => false, :limit => 3, :default => 1
      t.string      :description,         :null => true,  :limit => 200
      t.hstore      :metadata,            :null => true
      t.float       :price,               :null => false, :precision => 7, :scale => 2
      t.integer     :stock_level,         :null => false, :limit => 5, :default => 1
      t.boolean     :published,           :null => false, :default => false
      t.timestamp   :published_at,        :null => true
      t.string      :status,              :null => false, :limit => 20, :default => 'for_sale'

      t.user_tracking
      t.timestamps
    end
  end
end
