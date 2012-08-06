class IslayShop::Admin::OrderProcessesController < IslayShop::Admin::ApplicationController
  header 'Shop - Order Processing'
  nav 'islay_shop/admin/orders/nav'
  helper 'islay_shop/admin/orders'

  before_filter :status_counts

  def index
    redirect_to path(:billing, :order_processes)
  end

  def billing
    @title = 'Billing'
    @orders = OrderSummary.summary.billing.sorted(params[:sort])
    render :index
  end

  def packing
    @title = 'Packing'
    @orders = OrderSummary.summary.packing.sorted(params[:sort])
    render :index
  end

  def shipping
    @title = 'Shipping'
    @orders = OrderSummary.summary.shipping.sorted(params[:sort])
    render :index
  end

  def recent
    @title = 'Completed (last 7 days)'
    @orders = OrderSummary.summary.recently_completed.sorted(params[:sort])
    render :index
  end

  private

  def status_counts
    @counts = OrderSummary.status_counts
  end
end
