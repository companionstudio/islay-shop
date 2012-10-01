class OrderOverviewCell < Cell::Rails
  def index
    @counts = OrderSummary.status_counts

    finish = Date.today
    start = finish.weeks_ago(1)
    @series = OrderOverviewReport.series(
      :mode => :none,
      :days => (start..finish).map {|d| "#{d.mday}/#{d.month}/#{d.year}"}
    )

    render
  end
end
