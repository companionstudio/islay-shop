class IslayShop::Admin::ReportsController < IslayShop::Admin::ApplicationController
  before_filter :parse_dates, :only => [:index, :orders, :product, :sku]
  before_filter :parse_resolution
  nav_scope :reports

  def index
    @top_ten  = OrderOverviewReport.top_ten(@report_range)
    @series   = OrderOverviewReport.series(@report_range, @resolution)
    @totals   = OrderOverviewReport.aggregates(@report_range)
    @grand_totals = OrderOverviewReport.grand_totals
  end

  def month
    @top_ten  = OrderOverviewReport.top_ten(@report_range)
    @series   = OrderOverviewReport.series(@report_range)
    @totals   = OrderOverviewReport.aggregates(@report_range)
  end

  def totals
    @totals = OrderOverviewReport.grand_totals
  end

  def orders
    @series   = OrderOverviewReport.series(@report_range, @resolution)
    @totals   = OrderReport.aggregates(@report_range)
    @orders   = OrderReport.orders(@report_range)
  end

  def products
    @total_volume = ProductReport.total_volume
    @products     = ProductReport.product_summary
    @skus         = ProductReport.sku_summary

    @categories, @all_categories   = ProductReport.category_summary
  end

  def product
    @product  = Product.find(params[:id])
    @series   = ProductReport.product_series(@product.id, @report_range)
    @totals   = ProductReport.product_aggregates(@product.id, @report_range)
    @skus     = ProductReport.product_skus_summary(@product.id, @report_range)
    @orders   = ProductReport.orders(@product.id, @report_range)
  end

  def sku
    @product  = Product.find(params[:product_id])
    @sku      = Sku.find(params[:id])
    @series   = SkuReport.series(@sku.id, @report_range, @resolution)
    @totals   = SkuReport.aggregates(@sku.id, @report_range)
    @orders   = SkuReport.orders(@sku.id, @report_range)
  end

  private

  def parse_resolution
    @resolution = params[:resolution] || :daily
  end

  # Intended to be run as a before filter, which will then draw out date/time
  # related params, coerce them and put them into a Hash.
  #
  # @return Hash
  def parse_dates
    @report_range = if params[:month] and params[:year]
      now       = Date.today
      date      = Date.new(params[:year].to_i, params[:month].to_i)
      last_day  = date.month == now.month ? now.mday : date.end_of_month.mday

      {
        :mode       => :month,
        :start_date => date,
        :end_date   => last_day,
        :year       => params[:year].to_i,
        :month      => params[:month].to_i,
        :days       => (1..last_day).map {|d| "#{d}/#{date.month}/#{date.year}"}
      }
    elsif params[:from] and params[:to]
      from  = Date.parse(params[:from])
      to    = Date.parse(params[:to])

      {
        :mode       => :range,
        :start_date => from,
        :end_date   => to,
        :from       => params[:from],
        :to         => params[:to],
        :days       => (from..to).map {|d| "#{d.mday}/#{d.month}/#{d.year}"}
      }
    else
      now = Date.today

      {
        :mode       => :none,
        :start_date => now,
        :year       => now.year,
        :month      => now.month,
        :days       => (1..now.mday).map {|d| "#{d}/#{now.month}/#{now.year}"}
      }
    end

  end

  def set_range
    @from = params[:from] || default_date
    @to = params[:to]     || default_date
  end

  def default_date
    @default_date ||= begin
      meth = "beginning_of_#{params[:span]}"
      Time.now.send(meth).strftime('%Y-%m-%d')
    end
  end

  def find_start_date
    order = Order.order('created_at ASC').limit(1).first
    @start_date = order ? order.created_at : Time.now
  end
end
