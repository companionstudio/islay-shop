class OrderOverviewCell < Cell::Rails
  def index
    @counts = OrderSummary.status_counts
    render
  end
end
