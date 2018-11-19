class AlterPromotionsWithApplicationLimit < ActiveRecord::Migration[4.2]
  def up
    add_column(:promotions, :application_limit, :integer, :null => true, :precision => 7,  :scale => 0)
  end

  def down
    remove_column(:promotions, :application_limit)
  end
end
