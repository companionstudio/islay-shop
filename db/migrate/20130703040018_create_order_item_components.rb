class CreateOrderItemComponents < ActiveRecord::Migration
  def change
    create_table :order_item_components do |t|
      t.integer :order_item_id, :null => false, :on_delete  => :cascade
      t.string  :kind,          :null => false, :default    => 'regular' #enum: regular, discounted, bonus, calculated
      t.integer :quantity,      :null => false, :default    => 0, :limit => 10
      t.decimal :price,         :null => false, :default    => 0, :precision => 14,  :scale => 7
      t.decimal :total,         :null => false, :default    => 0, :precision => 14,  :scale => 7
    end
  end
end
