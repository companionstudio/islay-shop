class AlterOrdersAddTrackingReference < ActiveRecord::Migration
  def up
    add_column(:orders, :tracking_reference, :string, :limit => 30, :null => true)
  end

  def down
    remove_column(:orders, :tracking_reference)
  end
end
