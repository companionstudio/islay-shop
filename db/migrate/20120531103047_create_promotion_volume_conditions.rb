class CreatePromotionVolumeConditions < ActiveRecord::Migration
  def change
    create_table :promotion_volume_conditions do |t|
      t.integer :promotion_id, :null => false, :on_delete => :cascade

      t.timestamps
    end
  end
end
