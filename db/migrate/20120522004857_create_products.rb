class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.integer     :product_category_id, :null => false, :on_delete => :cascade
      t.integer     :product_range_id,    :null => true,  :on_delete => :set_null
      t.string      :name,                :null => false, :limit => 200, :index => {:unique => true, :with => 'product_category_id'}
      t.string      :description,         :null => false, :limit => 4000
      t.boolean     :published,           :null => false, :default => false
      t.timestamp   :published_at,        :null => true
      t.string      :status,              :null => false, :limit => 20, :default => 'for_sale'

      t.user_tracking
      t.timestamps
    end
  end
end
