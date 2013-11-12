# This migration comes from islay_engine (originally 20131029001701)
class AlterUsersWithDisabledFlag < ActiveRecord::Migration
  def up
    add_column(:users, :disabled, :boolean, :null => false, :default => false)
  end

  def down
    remove_column(:users, :disabled)
  end
end
