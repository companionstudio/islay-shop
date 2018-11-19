class CreateOrderAdjustments < ActiveRecord::Migration[4.2]
  def up
    create_table :order_adjustments do |t|
      t.integer :order_id,    :null => false, :on_delete => :cascade
      t.string  :source,      :null => false # enum: promotion, manual
      t.decimal :adjustment,  :null => false, :default => 0, :precision => 14, :scale => 7
      
      t.timestamps
    end

    # Generate order level adjustments
    execute(%{
      INSERT INTO order_adjustments (order_id, source, adjustment, created_at, updated_at)
      SELECT
        id,
        'promotion',
        discount,
        created_at,
        created_at
      FROM orders
      WHERE discount > 0
    })

    # Generate item level adjustments
    execute(%{
      INSERT INTO order_item_adjustments (order_item_id, kind, source, quantity, adjustment)
      SELECT 
        ois.id,
        'order_level',
        'promotion',
        ois.quantity,
        -(ois.total * (os.discount / os.original_total))
      FROM order_items AS ois
      JOIN orders AS os ON os.id = ois.order_id AND os.discount > 0
    })

    # Update order item totals
    execute(%{
      UPDATE order_items
      SET total = order_items.pre_discount_total + oias.adjustment
      FROM order_item_adjustments AS oias
      WHERE oias.order_item_id = order_items.id
    })
  end

  def down
    drop_table(:order_adjustments)
  end
end
