class AlterPromotionsWithNullableEndAt < ActiveRecord::Migration[4.2]
  def up
    change_column_null(:promotions, :end_at, true)
  end

  def down
    change_column_null(:promotions, :end_at, false)
  end
end
