class StockAlertsCell < IslayShop::ApplicationCell
  def index
    @alerts = Sku.alerts
    render
  end
end
