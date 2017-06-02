class AlterOrdersMakeStatesNullable < ActiveRecord::Migration
  def change
    change_column_null(:orders, :billing_state, true)
    change_column_null(:orders, :shipping_state, true)
    change_column_null(:orders, :billing_postcode, true)
    change_column_null(:orders, :shipping_postcode, true)
  end
end
