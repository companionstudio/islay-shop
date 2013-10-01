class CreateSkuPricePoints < ActiveRecord::Migration
  def up
    rename_table(:sku_price_logs, :legacy_sku_price_logs)

    create_table :sku_price_points do |t|
      t.integer :sku_id,          :null => false, :on_delete => :cascade
      t.integer :volume,          :null => true,  :limit => 20
      t.decimal :price,           :null => false, :precision => 14,  :scale => 7
      t.string  :mode,            :null => false, :limit => 15 # enum: bracketed, boxed, single
      t.boolean :current,         :null => false, :default => false

      t.datetime :valid_from,     :null => false
      t.datetime :valid_to,       :null => true
      
      t.user_tracking
    end

    execute(%{
      INSERT INTO sku_price_points (sku_id, volume, price, mode, current, valid_from, valid_to, creator_id, updater_id)
      SELECT * FROM (
        SELECT
          id AS sku_id, 
          1 AS volume, 
          price, 
          'single' AS mode, 
          true AS current, 
          created_at AS valid_from, 
          creator_id, 
          creator_id AS updater_id
        FROM skus

        UNION ALL

        SELECT
          id AS sku_id, 
          batch_size AS volume, 
          batch_price / batch_size, 
          'boxed' AS mode, 
          true AS current, 
          created_at AS valid_from, 
          creator_id, 
          creator_id AS updater_id
        FROM skus
        WHERE batch_price > 0 AND batch_size > 0
      ) AS points
    })
  end

  def down
    drop_table(:sku_price_points)
    rename_table(:legacy_sku_price_logs, :sku_price_logs)
  end
end
