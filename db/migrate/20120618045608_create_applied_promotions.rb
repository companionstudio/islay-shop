class CreateAppliedPromotions < ActiveRecord::Migration
  def change
    create_table :applied_promotions do |t|
      t.integer :promotion_id,              :null => false
      t.integer :promotion_effect_id,       :null => false
      t.integer :order_id,                  :null => false, :on_delete => :cascade
      t.integer :qualifying_order_item_id,  :null => false
      t.integer :bonus_order_item_id,       :null => false

      t.timestamp :created_at
    end
  end
end
