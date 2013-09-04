class IslayShop::Public::CheckoutController < IslayShop::Public::ApplicationController
  include IslayShop::Payments
  include IslayShop::ControllerExtensions::Public

  use_https

  before_filter :check_for_order_contents,   :except => [:thank_you]
  before_filter :fetch_promotions,  :only   => [:basket, :details, :thank_you]

  def details
  end

  def update
    order.update_details(params[:order_basket])
    session['order'] = @order.dump
    if @order.valid?
      redirect_to path(:order_checkout_payment)
    else
      render :details
    end
  end

  def payment
    @payment = PaymentSubmission.new
  end

  def payment_process
    result = payment_provider.confirm_payment_submission(request.env["QUERY_STRING"])
    @payment = PaymentSubmission.new(result)

    if result.successful?
      order.run!(:add, result)
      flash['order'] = session['order'] #keep the order around for the next request only
      session.delete('order')
      redirect_to path(:order_checkout_thank_you, :reference => order.reference)
    else
      render :payment
    end
  end

  def thank_you
    unless flash['order'].blank?
      # Yuck! 
      # Keep a record of the order in flash until the user leaves the page - basically, allow refreshes of the thankyou page.
      flash['order'] = flash['order'] 
    end
  end

  private

  # This is made annoying by the fact that @order is set by a before filter in the application controller
  # This workaround checks the session dump directly.
  def check_for_order_contents
    if order.empty?
      redirect_to path(:order_basket)
    end
  end

  def fetch_promotions
    #Any promotions that can be qualified for at the checkout (code based)
    @checkout_promotions = Promotion.active_code_based

    #Any promotions ready to be applied to the order
    if order and !order.pending_promotions.empty?
      @promotions = order.pending_promotions
    end

  end
end
