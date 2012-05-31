class CreatePromotionShippingEffects < ActiveRecord::Migration
  def change
    create_table :promotion_shipping_effects do |t|
      t.integer :promotion_id, :null => false, :on_delete => :cascade

      t.timestamps
    end
  end
end
