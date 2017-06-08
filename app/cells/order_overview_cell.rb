class OrderOverviewCell < Cell::Rails
  def index
    @counts = OrderSummary.status_counts

    @processing_required = @counts[:processable] > 0

    finish = Date.today
    start = Date.today.beginning_of_month
    @series = OrderOverviewReport.series(
      :mode => :none,
      :days => (start..finish).map {|d| "#{d.mday}/#{d.month}/#{d.year}"}
    )

    render
  end
end
