class IslayShop::Public::CheckoutController < IslayShop::Public::ApplicationController
  private

  def load_order
    if session['order']
      @order = OrderCheckout.load(JSON.parse(session['order']))
    end
  end
end
