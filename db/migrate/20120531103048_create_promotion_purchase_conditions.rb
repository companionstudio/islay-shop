class CreatePromotionPurchaseConditions < ActiveRecord::Migration
  def change
    create_table :promotion_purchase_conditions do |t|
      t.integer :promotion_id, :null => false, :on_delete => :cascade

      t.timestamps
    end
  end
end
