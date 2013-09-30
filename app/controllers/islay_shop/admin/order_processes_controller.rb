class IslayShop::Admin::OrderProcessesController < IslayShop::Admin::ApplicationController
  header 'Orders - Processing'
  nav_scope :orders
  helper 'islay_shop/admin/orders'

  before_filter :status_counts
  before_filter :find_order, :only => [:review_billing, :bill, :review_cancellation, :cancel, :pack, :ship, :review_cancellation, :cancel, :update]

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
    @order.run!(:bill)
    redirect_to path(:order, :id => @order)
  end

  def review_cancellation
    render :layout => !request.xhr?
  end

  def cancel
    @order.run!(:cancel)
    redirect_to path(:order, :id => @order)
  end

  def packing
    @title = 'Packing'
    @orders = OrderSummary.alt_summary.packing.page(params[:page]).sorted(params[:sort])
  end

  def pack
    @order.run!(:pack)
    redirect_to path(:order, :id => @order)
  end

  def pack_all
    if params[:all]
      ids = OrderSummary.packing.pluck(:id)
      OrderProcess.run_all!(:pack, ids)
    else
      OrderProcess.run_all!(:pack, params[:ids])
    end

    redirect_to path(:packing, :order_processes)
  end

  def shipping
    @title = 'Shipping'
    @orders = OrderSummary.alt_summary.shipping.page(params[:page]).sorted(params[:sort])
  end

  def ship
    @order.run!(:ship)
    redirect_to path(:order, :id => @order)
  end

  def ship_all
    if params[:all]
      ids = OrderSummary.shipping.pluck(:id)
      OrderProcess.run_all!(:ship, ids)
    else
      OrderProcess.run_all!(:ship, params[:ids])
    end

    redirect_to path(:shipping, :order_processes)
  end

  def recent
    @title = 'Completed (last 7 days)'
    @orders = OrderSummary.summary.recently_completed.page(params[:page]).sorted(params[:sort])
  end

  def update
    @order.update_attributes(params[:order])
    redirect_to path(:order, :id => @order)
  end

  private

  def status_counts
    @counts = OrderSummary.status_counts
  end

  def find_order
    @order = OrderProcess.find(params[:id])
  end
end
