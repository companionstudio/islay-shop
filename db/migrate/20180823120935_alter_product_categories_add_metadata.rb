class AlterProductCategoriesAddMetadata < ActiveRecord::Migration
  def change
    add_column :product_categories, :metadata, :hstore, :null => true
  end
end
