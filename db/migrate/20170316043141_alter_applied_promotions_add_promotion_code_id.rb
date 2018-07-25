class AlterAppliedPromotionsAddPromotionCodeId < ActiveRecord::Migration[4.2]
  def change
      add_column(:applied_promotions, :promotion_code_id, :integer, :references => :promotion_codes, :null => true)
  end
end
