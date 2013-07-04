class AlterSkusForPricingRestructure < ActiveRecord::Migration
  def up
    # Backup existing SKUs
    execute(%{
      CREATE TABLE legacy_skus (LIKE skus INCLUDING INDEXES);
      INSERT INTO legacy_skus SELECT * FROM skus
    })

    remove_column(:skus, :price)
    remove_column(:skus, :batch_size)
    remove_column(:skus, :batch_price)
  end

  def down
    add_column(:skus, :price,       :float,   :null => true, :precision => 7, :scale => 2)
    add_column(:skus, :batch_size,  :integer, :null => true,  :limit => 5)
    add_column(:skus, :batch_price, :float,   :null => true,  :precision => 7, :scale => 2)

    # Restore from backed up table
    execute(%{
      UPDATE skus 
      SET price = ls.price, batch_size = ls.batch_size, batch_price = ls.batch_price
      FROM legacy_skus AS ls WHERE ls.id = skus.id
    })

    change_column_null(:skus, :price, false)

    # Removed the backup
    drop_table(:legacy_skus)
  end
end