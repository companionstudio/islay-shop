class CreateProductVariants < ActiveRecord::Migration[4.2]
  def change
    create_table :product_variants do |t|
      t.integer     :product_id,  :null => false, :on_delete => :cascade
      t.integer     :position,    :null => false, :limit => 3, :default => 1
      t.string      :name,        :null => false, :limit => 200
      t.string      :description,         :null => false, :limit => 4000
      t.boolean     :published,           :null => false, :default => false
      t.timestamp   :published_at,        :null => true
      t.string      :status,              :null => false, :limit => 20, :default => 'for_sale'

      t.timestamps
    end
  end
end
