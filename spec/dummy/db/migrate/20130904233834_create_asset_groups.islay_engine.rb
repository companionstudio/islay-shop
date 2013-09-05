# This migration comes from islay_engine (originally 20120516094638)
class CreateAssetGroups < ActiveRecord::Migration
  def change
    create_table :asset_groups do |t|
      t.string    :type,            :null => false, :limit => 50
      t.string    :name,            :null => false, :limit => 200
      t.integer   :assets_count,    :null => false, :limit => 10, :default => 0
      t.integer   :creator_id,      :null => false, :references => :users
      t.integer   :updater_id,      :null => false, :references => :users

      t.timestamps
    end

    add_column(:asset_groups, :terms, :tsvector)
    add_column(:asset_groups, :path, :ltree, :null => true)
  end
end
