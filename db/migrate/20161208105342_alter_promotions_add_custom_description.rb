class AlterPromotionsAddCustomDescription < ActiveRecord::Migration
  def change
    add_column(:promotions, :custom_description, :string, :limit => 2000)
  end
end
