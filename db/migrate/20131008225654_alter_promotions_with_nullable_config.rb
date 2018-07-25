class AlterPromotionsWithNullableConfig < ActiveRecord::Migration[4.2]
  def up
    change_column_null(:promotion_conditions, :config, true)
    change_column_null(:promotion_effects, :config, true)
  end

  def down
    change_column_null(:promotion_conditions, :config, false)
    change_column_null(:promotion_effects, :config, false)
  end
end
