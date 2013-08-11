class AlterSkusAddUnitCount < ActiveRecord::Migration
  def up
    add_column(:skus, :unit_count, :integer, :null => false, :default => 1)

    execute %{
      UPDATE skus
      SET unit_count = 3
      WHERE metadata->'freight_class' = 'three_pack';
    }
  end

  def down
    remove_column(:skus, :unit_count)
  end
end
