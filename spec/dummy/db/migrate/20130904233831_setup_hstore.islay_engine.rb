# This migration comes from islay_engine (originally 20120515043400)
class SetupHstore < ActiveRecord::Migration
  def self.up
    execute "CREATE EXTENSION hstore"
  end

  def self.down
    execute "DROP EXTENSION hstore"
  end
end
