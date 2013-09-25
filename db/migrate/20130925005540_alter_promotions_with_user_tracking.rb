class AlterPromotionsWithUserTracking < ActiveRecord::Migration
  def up
    add_column(:promotions, :creator_id, :integer, :references => :users, :null => false)
    add_column(:promotions, :updater_id, :integer, :references => :users, :null => false)
  end

  def down
    remove_column(:promotions, :creator_id)
    remove_column(:promotions, :updater_id)
  end
end
