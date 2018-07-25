class CreateProductRanges < ActiveRecord::Migration[4.2]
  def change
    create_table :product_ranges do |t|
      t.integer :asset_id,      :null => true
      t.string  :name,          :null => false, :limit => 255, :index => :unique
      t.string  :slug,          :null => false, :limit => 255, :index => :unique
      t.string  :description,   :null => false, :limit => 4000

      t.publishing
      t.user_tracking
      t.timestamps
    end

    add_column(:product_ranges, :terms, :tsvector)
  end
end
