# This migration comes from islay_engine (originally 20120515043401)
class CreateLtreeExtension < ActiveRecord::Migration
  def up
    execute "CREATE EXTENSION ltree"
  end

  def down
    execute "DROP EXTENSION ltree"
  end
end
