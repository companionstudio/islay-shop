class IslayShop::Admin::OrdersController < IslayShop::Admin::ApplicationController
  resourceful :order
  header 'Orders'
  nav_scope :orders

  def index
    @orders = OrderSummary.summary.processing.page(params[:page]).sorted(params[:sort])
    @counts = OrderSummary.status_counts
  end

  def edit_payment

  end

  def update_payment

  end
end
