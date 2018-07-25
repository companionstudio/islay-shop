class AlterOfferOrdersAddQuantityMultiplier < ActiveRecord::Migration[4.2]
  def change
    add_column(:offer_orders, :quantity_multiplier, :integer, :default => 1)
  end
end
