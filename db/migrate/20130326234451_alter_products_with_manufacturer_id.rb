class AlterProductsWithManufacturerId < ActiveRecord::Migration[4.2]
  def up
    add_column(:products, :manufacturer_id, :integer, :null => true, :on_delete => :set_null)
  end

  def down
    remove_column(:products, :manufacturer_id)
  end
end

