class AlterOrderItemsForPricingRestructure < ActiveRecord::Migration
  def up
    # Backup table
    execute(%{
      CREATE TABLE legacy_order_items (LIKE order_items INCLUDING INDEXES);
      INSERT INTO legacy_order_items SELECT * FROM order_items
    })

    # Update type on order_items to be 'SkuOrderItem'
    execute("UPDATE order_items SET type = 'SkuOrderItem'")

    # Generate components
    execute(%{
      INSERT INTO order_item_components (order_item_id, quantity, price, total)
      SELECT *
      FROM (
        SELECT id, quantity, original_price AS price, total
        FROM order_items WHERE batch_price IS NULL

        UNION

        SELECT id, quantity, batch_price / quantity AS price, total
        FROM order_items WHERE batch_price IS NOT NULL AND (quantity % batch_size) = 0

        UNION

        SELECT id, (quantity - (quantity % batch_size)) AS quantity, batch_price / (quantity - (quantity % batch_size)) AS price, total
        FROM order_items WHERE batch_price IS NOT NULL AND (quantity % batch_size) > 0

        UNION

        SELECT id, (quantity % batch_size) AS quantity, original_price AS price, total
        FROM order_items WHERE batch_price IS NOT NULL AND (quantity % batch_size) > 0
      ) AS items
    })    

    # Add and modify some existing columns
    change_column_null(:order_items, :sku_id, true)
    add_column(:order_items, :service_id, :integer, :null => true)
    rename_column(:order_items, :original_price, :price)

    # Generate shipping items + components
    execute(%{
      INSERT INTO order_items (order_id, quantity, type, price, total, created_at, updated_at, service_id)
      SELECT 
        id AS order_id,
        1 AS quantity,
        'ServiceOrderItem' AS type,
        shipping_total AS price,
        shipping_total AS total,
        orders.created_at AS created_at,
        orders.created_at AS updated_at,
        (SELECT id FROM services WHERE key = 'shipping' LIMIT 1) AS service_id
      FROM orders;

      INSERT INTO order_item_components (order_item_id, kind, quantity, price, total)
      SELECT id, 'calculated', 1, price, total
      FROM order_items WHERE type = 'ServiceOrderItem'
    })

    # Generate Adjustments
    execute(%{
      INSERT INTO order_item_adjustments (order_item_id, kind, source, quantity, adjustment)
      SELECT 
        ois.id AS order_item_id,
        'order_level' AS kind,
        'promotion' AS source,
        ois.quantity,
        ois.total * (os.percentage / 100) AS adjustment
      FROM (SELECT id, (discount / original_product_total * 100) AS percentage FROM orders WHERE discount > 0) AS os
      JOIN order_items AS ois ON ois.order_id = os.id
    })

    # Remove old columns
    remove_column(:order_items, :batch_size)
    remove_column(:order_items, :batch_price)
    remove_column(:order_items, :original_total)
    remove_column(:order_items, :adjusted_price)

    # Alter existing columns for precision
    change_column(:order_items, :discount, :decimal, :precision => 14, :scale => 7)
    change_column(:order_items, :total, :decimal, :precision => 14, :scale => 7)
    change_column(:order_items, :price, :decimal, :precision => 14, :scale => 7)
  end

  def down
    # Add columns back
    add_column(:order_items, :batch_size,     :integer, :null => true, :limit => 5)
    add_column(:order_items, :batch_price,    :float,   :null => true, :precision => 7, :scale => 5)
    add_column(:order_items, :original_total, :float,   :null => true, :precision => 7, :scale => 5)
    add_column(:order_items, :adjusted_price, :float,   :null => true, :precision => 7, :scale => 5)

    # Alter columns back
    change_column(:order_items, :discount, :float, :precision => 7, :scale => 2)
    change_column(:order_items, :total, :float, :precision => 7, :scale => 2)
    change_column(:order_items, :price, :float, :precision => 7, :scale => 2)

    # Rename columns and remove additions
    rename_column(:order_items, :price, :original_price)
    remove_column(:order_items, :service_id)


    # Add back old data
    execute(%{
      UPDATE order_items AS ois
      SET 
        batch_size = lois.batch_size,
        batch_price = lois.batch_price,
        original_total = lois.original_total,
        discount = lois.original_total,
        adjusted_price = lois.adjusted_price
      FROM legacy_order_items AS lois WHERE lois.id = ois.id;
    })

    # Change column nulls
    change_column_null(:order_items, :original_price, false)
    change_column_null(:order_items, :original_total, false)
    change_column_null(:order_items, :adjusted_price, false)
    change_column_null(:order_items, :sku_id, true)

    # Clear components
    execute("DELETE FROM order_item_components")

    # Clear adjustments
    execute("DELETE FROM order_item_adjustments")

    # Remove backup
    drop_table(:legacy_order_items)
  end
end
