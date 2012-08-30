class IslayShop::Public::CheckoutController < IslayShop::Public::ApplicationController
  before_filter :check_for_order, :except => [:thank_you]

  def details
  end

  def update
    @order.attributes = params[:order_basket]
    if @order.valid?
      session['order'] = @order.dump
      redirect_to path(:order_checkout_payment)
    else
      render :details
    end
  end

  def payment

  end

  def payment_process

  end

  def thank_you

  end

  private

  def check_for_order
    if session['order']
      @order = OrderBasket.load(session['order'])
      redirect_to path(:order_basket) if @order.empty?
    else
      redirect_to path(:order_basket)
    end
  end
end
