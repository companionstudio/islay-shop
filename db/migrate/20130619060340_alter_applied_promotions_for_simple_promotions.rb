class AlterAppliedPromotionsForSimplePromotions < ActiveRecord::Migration[4.2]
  def up
    #This migration assumes no promotions have been applied - no legacy table is created.
    drop_table(:applied_promotions)
    create_table(:applied_promotions) do |t|
      t.integer :order_id,      :null => false, :on_delete => :cascade, :index => {:unique => true, :with => [:promotion_id] }
      t.integer :promotion_id,  :null => false, :on_delete => :cascade
    end
  end

  def down
    drop_table(:applied_promotions)
    create_table :applied_promotions do |t|
      t.integer :promotion_id,              :null => false
      t.integer :promotion_effect_id,       :null => false
      t.integer :order_id,                  :null => false, :on_delete => :cascade
      t.integer :qualifying_order_item_id,  :null => true,  :references => :order_items
      t.integer :bonus_order_item_id,       :null => true,  :references => :order_items

      t.timestamp :created_at
    end
  end
end
