class CreatePromotionProductDiscountEffects < ActiveRecord::Migration
  def change
    create_table :promotion_product_discount_effects do |t|
      t.integer :promotion_id, :null => false, :on_delete => :cascade

      t.timestamps
    end
  end
end
