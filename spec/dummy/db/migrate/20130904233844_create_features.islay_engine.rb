# This migration comes from islay_engine (originally 20121003020810)
class CreateFeatures < ActiveRecord::Migration
  def change
    create_table :features do |t|
      t.integer :page_id,             :null => false, :on_delete => :cascade
      t.integer :primary_asset_id,    :null => true,  :on_delete => :set_null, :references => :assets
      t.integer :secondary_asset_id,  :null => true,  :on_delete => :set_null, :references => :assets

      t.integer :position,        :null => false, :limit => 3,  :default => 1
      t.string  :title,           :null => false, :length => 200
      t.string  :description,     :null => true,  :length => 4000
      t.string  :styles,          :null => true,  :length => 4000

      t.publishing
      t.user_tracking
      t.timestamps
    end
  end
end
