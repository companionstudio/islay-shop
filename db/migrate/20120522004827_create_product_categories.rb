class CreateProductCategories < ActiveRecord::Migration
  def change
    create_table :product_categories do |t|
      t.integer     :asset_id,            :null => true
      t.integer     :position,            :null => false, :limit => 3, :default => 1
      t.string      :name,                :null => false, :limit => 255
      t.string      :slug,                :null => false, :limit => 255
      t.string      :description,         :null => false, :limit => 4000
      t.string      :status,              :null => false, :limit => 20, :default => 'for_sale'

      t.publishing
      t.user_tracking
      t.timestamps
    end

    add_column(:product_categories, :terms, :tsvector)
    add_column(:product_categories, :path, :ltree, :null => true)
  end
end
