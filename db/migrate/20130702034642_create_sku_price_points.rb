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

    # This scary query does the following
    # * Figures out the unique price points (price+volume) and their first and 
    #   last date of sale based on order_items
    # * Counts the total number of unique price points sold per sku
    # * Creates a set of all price points based on order_items and skus, with
    #   current being calculated.
    # * Determines the valid_from and valid_to based on current status and the
    #   overlap between first sale and last sale date for each price point.
    execute(%{
      WITH items AS (
        SELECT sku_id, volume, price, MIN(created_at) AS first_sale_at, MAX(created_at) AS last_sale_at
        FROM (
          SELECT sku_id, created_at, COALESCE(batch_size, 1) AS volume, COALESCE(batch_price, original_price) AS price
          FROM order_items
        ) AS items
        GROUP BY sku_id, volume, price
      ),
      counts AS (
        SELECT sku_id, COUNT(*) AS total 
        FROM items
        GROUP BY sku_id
      ),
      prices AS (
        SELECT
          prices.*,
          CASE
            WHEN prices.mode = 'single' AND prices.price = skus.price THEN true
            WHEN prices.mode = 'boxed' AND prices.price = skus.batch_price THEN true
            ELSE false
          END AS current,
          skus.creator_id,
          skus.updater_id,
          skus.created_at,
          skus.updated_at
        FROM (
          SELECT sku_id, 1 AS volume, original_price AS price, 'single' AS mode
          FROM order_items WHERE batch_price IS NULL

          UNION

          SELECT sku_id, batch_size AS volume, batch_price / batch_size AS price, 'boxed' AS mode
          FROM order_items WHERE batch_price IS NOT NULL AND batch_size IS NOT NULL AND batch_size > 0

          UNION

          SELECT id AS sku_id, 1 AS volume, price, 'single' AS mode
          FROM skus

          UNION

          SELECT id AS sku_id, batch_size AS volume, batch_price / batch_size AS price, 'boxed' AS mode
          FROM skus WHERE batch_price IS NOT NULL AND batch_size IS NOT NULL AND batch_size > 0
        ) AS prices
        JOIN skus ON skus.id = prices.sku_id
      )

      INSERT INTO sku_price_points (sku_id, volume, price, mode, current, valid_from, valid_to, creator_id, updater_id)
      SELECT
        prices.sku_id,
        prices.volume,
        prices.price,
        mode,
        current,
        CASE
          WHEN current AND (counts.total = 1 OR counts.total IS NULL) THEN created_at
          WHEN current AND (counts.total > 1) THEN items.first_sale_at
          ELSE created_at
        END AS valid_from,
        CASE
          WHEN current THEN NULL
          WHEN items.sku_id IS NOT NULL THEN items.last_sale_at
          ELSE prices.updated_at
        END AS valid_to,
        creator_id,
        updater_id
      FROM prices
      LEFT JOIN counts ON counts.sku_id = prices.sku_id
      LEFT JOIN items ON items.sku_id = prices.sku_id AND items.volume = prices.volume AND items.price = prices.price    
    })
  end

  def down
    drop_table(:sku_price_points)
    rename_table(:legacy_sku_price_logs, :sku_price_logs)
  end
end
