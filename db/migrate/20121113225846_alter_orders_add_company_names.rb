class AlterOrdersAddCompanyNames < ActiveRecord::Migration
  def up
    add_column(:orders, :billing_company, :string, :limit => 200)
    add_column(:orders, :shipping_company, :string, :limit => 200)
    rename_column(:orders, :gifted_to, :shipping_name)
  end

  def down
    remove_column(:orders, :billing_company)
    remove_column(:orders, :shipping_company)
    rename_column(:orders, :shipping_name, :gifted_to)
  end
end
