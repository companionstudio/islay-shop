class StockAlertsCell < Cell::Rails
  def index
    @alerts = Sku.alerts
    render
  end
end
