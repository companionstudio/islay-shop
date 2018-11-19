class AlterPromotionsWithUserTracking < ActiveRecord::Migration[4.2]
  def up
    add_column(:promotions, :creator_id, :integer, :references => :users)
    add_column(:promotions, :updater_id, :integer, :references => :users)

    execute(%{
      UPDATE promotions
      SET
        creator_id = (SELECT id FROM users WHERE email = 'system@spookandpuff.com' OR email = 'lukeandben@spookandpuff.com' LIMIT 1),
        updater_id = (SELECT id FROM users WHERE email = 'system@spookandpuff.com' OR email = 'lukeandben@spookandpuff.com' LIMIT 1)
    })

    change_column_null(:promotions, :creator_id, false)
    change_column_null(:promotions, :updater_id, false)
  end

  def down
    remove_column(:promotions, :creator_id)
    remove_column(:promotions, :updater_id)
  end
end
