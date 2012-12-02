class IslayShop::Public::CheckoutController < IslayShop::Public::ApplicationController
  use_https

  before_filter :check_for_order, :except => [:thank_you]

  def details
  end

  def update
    @order.update_details(params[:order_basket])
    session['order'] = @order.dump
    if @order.valid?
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
      flash[:order] = session['order'] #keep the order around for the next request only
      session.delete('order')
      redirect_to path(:order_checkout_thank_you)
    else
      render :payment
    end
  end

  def thank_you
    unless flash[:order].blank?
      @order = OrderBasket.load(flash[:order]) 
      # Yuck! 
      # Keep a record of the order in flash until the user leaves the page - basically, allow refreshes of the thankyou page.
      flash[:order] = flash[:order] 
    end
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
