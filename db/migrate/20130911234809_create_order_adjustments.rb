class CreateOrderAdjustments < ActiveRecord::Migration
  def change
    create_table :order_adjustments do |t|
      t.integer :order_id,    :null => false, :on_delete => :cascade
      t.string  :source,      :null => false # enum: promotion, manual
      t.decimal :adjustment,  :null => false, :default => 0, :precision => 14, :scale => 7
      
      t.timestamps
    end
  end
end
