class AlterOrdersForPricingRestructure < ActiveRecord::Migration[4.2]
  def up
    execute(%{
      CREATE TABLE legacy_orders (LIKE orders INCLUDING INDEXES);
      INSERT INTO legacy_orders SELECT * FROM orders
    })

    add_column(:orders, :increase, :decimal, :precision => 14, :scale => 7)
    add_column(:orders, :on_hold, :boolean, :null => false, :default => false)

    change_column(:orders, :product_total,          :decimal, :precision => 14, :scale => 7)
    change_column(:orders, :original_product_total, :decimal, :precision => 14, :scale => 7)
    change_column(:orders, :total,                  :decimal, :precision => 14, :scale => 7)
    change_column(:orders, :original_total,         :decimal, :precision => 14, :scale => 7)
    change_column(:orders, :discount,               :decimal, :precision => 14, :scale => 7)

    remove_column(:orders, :shipping_total)
    remove_column(:orders, :original_shipping_total)
  end

  def down
    remove_column(:orders, :increase)
    remove_column(:orders, :on_hold)

    change_column(:orders, :product_total,           :float, :precision => 7, :scale => 2)
    change_column(:orders, :original_product_total,  :float, :precision => 7, :scale => 2)
    change_column(:orders, :total,                   :float, :precision => 7, :scale => 2)
    change_column(:orders, :original_total,          :float, :precision => 7, :scale => 2)
    change_column(:orders, :discount,                :float, :precision => 7, :scale => 2)

    add_column(:orders, :shipping_total,          :float, :precision => 7, :scale => 2)
    add_column(:orders, :original_shipping_total, :float, :precision => 7, :scale => 2)

    execute(%{
      UPDATE orders AS os
      SET 
        product_total = los.product_total,
        original_product_total = los.original_product_total,
        total = los.total,
        original_total = los.original_total,
        shipping_total = los.shipping_total,
        original_shipping_total = los.original_shipping_total
      FROM legacy_orders AS los WHERE los.id = os.id;
    })

    drop_table(:legacy_orders)
  end
end
