class CreatePromotionBonusEffects < ActiveRecord::Migration
  def change
    create_table :promotion_bonus_effects do |t|
      t.integer :promotion_id, :null => false, :on_delete => :cascade

      t.timestamps
    end
  end
end
