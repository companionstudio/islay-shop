class IslayShop::Admin::OrdersController < IslayShop::Admin::ApplicationController
  header 'Orders'

  def index
    @orders = Order.all
  end

  def show

  end
end
