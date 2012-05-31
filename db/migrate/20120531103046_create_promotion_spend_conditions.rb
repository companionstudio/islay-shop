class CreatePromotionSpendConditions < ActiveRecord::Migration
  def change
    create_table :promotion_spend_conditions do |t|
      t.integer :promotion_id, :null => false, :on_delete => :cascade

      t.timestamps
    end
  end
end
