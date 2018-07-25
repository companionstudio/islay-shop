class AlterSkusAddUnitCount < ActiveRecord::Migration[4.2]
  def up
    add_column(:skus, :unit_count, :integer, :null => false, :default => 1)
  end

  def down
    remove_column(:skus, :unit_count)
  end
end
