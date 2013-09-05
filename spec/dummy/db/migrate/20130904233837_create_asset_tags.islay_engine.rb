# This migration comes from islay_engine (originally 20120812002303)
class CreateAssetTags < ActiveRecord::Migration
  def change
    create_table :asset_tags do |t|
      t.string :name, :null => false, :limit => 200
      t.string :slug, :null => false, :limit => 200, :unique => true
    end
  end
end
