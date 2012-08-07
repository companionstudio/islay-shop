class IslayShop::Admin::OrdersController < IslayShop::Admin::ApplicationController
  resourceful :order
  header 'Orders'
  nav 'nav'

  def index
    @orders = OrderSummary.summary.processing.page(params[:page]).sorted(params[:sort])
  end

  def edit_payment

  end

  def update_payment

  end
end