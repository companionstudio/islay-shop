class IslayShop::Admin::OrderProcessesController < IslayShop::Admin::ApplicationController
  header 'Shop - Order Processing'
  nav 'islay_shop/admin/orders/nav'
  helper 'islay_shop/admin/orders'

  before_filter :status_counts
  before_filter :find_order, :only => [:review_billing, :bill, :pack, :ship]

  def index
    redirect_to path(:billing, :order_processes)
  end

  def billing
    @title = 'Billing'
    @orders = OrderSummary.summary.billing.page(params[:page]).sorted(params[:sort])
  end

  def review_billing

  end

  def bill

  end

  def packing
    @title = 'Packing'
    @orders = OrderSummary.summary.packing.page(params[:page]).sorted(params[:sort])
    render :index
  end

  def pack

  end

  def pack_all

  end

  def shipping
    @title = 'Shipping'
    @orders = OrderSummary.summary.shipping.page(params[:page]).sorted(params[:sort])
    render :index
  end

  def ship

  end

  def ship_all

  end

  def recent
    @title = 'Completed (last 7 days)'
    @orders = OrderSummary.summary.recently_completed.page(params[:page]).sorted(params[:sort])
    render :index
  end

  private

  def status_counts
    @counts = OrderSummary.status_counts
  end

  def find_order
    @order = OrderProcess.find(params[:id])
  end
end
