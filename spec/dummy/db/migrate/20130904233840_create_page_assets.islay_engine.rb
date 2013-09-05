# This migration comes from islay_engine (originally 20120827230009)
class CreatePageAssets < ActiveRecord::Migration
  def change
    create_table :page_assets do |t|
      t.integer :page_id,   :null => false, :on_delete => :cascade
      t.integer :asset_id,  :null => false, :on_delete => :cascade
      t.string  :name,      :null => false, :limit => 50
    end
  end
end
