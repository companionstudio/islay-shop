class IslayShop::Admin::ReportsController < IslayShop::Admin::ApplicationController
  def index
    @top_ten  = OrderOverviewReport.top_ten
    @series   = OrderOverviewReport.series
    @totals   = OrderOverviewReport.aggregates
  end
end
