class RenamePriceLogsForPricingRestructure < ActiveRecord::Migration
  def up
    rename_table(:sku_price_logs, :legacy_sku_price_logs)
  end

  def down
    rename_table(:legacy_sku_price_logs, :sku_price_logs)
  end
end
