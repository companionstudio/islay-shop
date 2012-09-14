class IslayShop::Admin::ReportsController < IslayShop::Admin::ApplicationController
  before_filter :parse_dates, :only => [:index]

  def index
    @top_ten  = OrderOverviewReport.top_ten(@report_range)
    @series   = OrderOverviewReport.series(@report_range)
    @totals   = OrderOverviewReport.aggregates(@report_range)
  end

  def orders

  end

  def products
    @total_volume = ProductReport.total_volume
    @products     = ProductReport.product_summary
    @skus         = ProductReport.sku_summary

    @categories, @all_categories   = ProductReport.category_summary
  end
end
