class IslayShop::Admin::ReportsController < IslayShop::Admin::ApplicationController
  def index
    @top_ten  = OrderOverviewReport.top_ten
    @series   = OrderOverviewReport.series
    @totals   = OrderOverviewReport.aggregates
  end

  def orders

  end

  def products
    @total_volume = ProductReport.total_volume
    @listing = ProductReport.listing
  end
end
