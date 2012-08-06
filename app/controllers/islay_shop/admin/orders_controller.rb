class IslayShop::Admin::OrdersController < IslayShop::Admin::ApplicationController
  resourceful :order
  header 'Orders'
  nav 'nav'

  def index
    @orders = OrderSummary.summary.page(params[:page]).sorted(params[:sort])
  end
end
