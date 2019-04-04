class OrderOverviewCell < IslayShopCell
  def index

    finish = Date.today
    start = Date.today.beginning_of_month

    @counts = OrderSummary.status_counts
    @popularity = OrderOverviewReport.top_ten({mode: :none})

    @month_sales = OrderOverviewReport.sales(Date.today.beginning_of_month..Date.today)
    @year_sales = OrderOverviewReport.sales(Date.today.beginning_of_year..Date.today)
    @all_time_sales = OrderOverviewReport.grand_totals.symbolize_keys

    @processing_required = @counts[:processable] > 0

    render
  end
end
