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
    @payment = CreditCardPayment.new
  end

  def payment_process
    @payment = CreditCardPayment.new(:gateway_id => params[:token], :amount => @order.total)
    @order.credit_card_payment = @payment

    if @order.run(:add)
      @order.save!
      session.delete('order')
      redirect_to path(:order_checkout_thank_you)
    else
      render :payment
    end
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
