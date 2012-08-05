class IslayShop::Admin::OrdersController < IslayShop::Admin::ApplicationController
  resourceful :order
  header 'Orders'
  nav 'nav'

  def index
    @orders = Order.all
  end

  def derp

  end

  def archived

  end
end
