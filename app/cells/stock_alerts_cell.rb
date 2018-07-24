class StockAlertsCell < IslayShopCell
  def index
    @alerts = Sku.alerts
    render
  end
end
