class AlterProductRangesAddMetadata < ActiveRecord::Migration
  def change
    add_column :product_ranges, :metadata, :hstore, :null => true
    add_column(:product_ranges, :published, :boolean, :null => false, :default => true)
  end
end
