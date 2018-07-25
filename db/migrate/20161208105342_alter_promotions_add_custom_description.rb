class AlterPromotionsAddCustomDescription < ActiveRecord::Migration[4.2]
  def change
    add_column(:promotions, :custom_description, :string, :limit => 2000)
  end
end
