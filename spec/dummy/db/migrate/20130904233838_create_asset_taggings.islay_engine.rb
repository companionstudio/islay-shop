# This migration comes from islay_engine (originally 20120812002304)
class CreateAssetTaggings < ActiveRecord::Migration
  def change
    create_table :asset_taggings do |t|
      t.integer :asset_id,      :null => false, :on_delete => :cascade
      t.integer :asset_tag_id,  :null => false, :on_delete => :cascade
    end
  end
end
