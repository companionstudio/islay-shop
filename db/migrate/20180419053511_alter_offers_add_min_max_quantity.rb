class AlterOffersAddMinMaxQuantity < ActiveRecord::Migration[4.2]
  def change
    add_column(:offers, :min_quantity, :integer, :default => 0, :null => false)
    add_column(:offers, :default_quantity, :integer, :default => 1, :null => false)
    add_column(:offers, :max_quantity, :integer, :default => 1, :null => true)
  end
end
