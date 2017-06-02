class IslayShop::Public::CheckoutController < IslayShop::Public::ApplicationController
  include IslayShop::Payments
  include IslayShop::ControllerExtensions::Public

  use_https
  before_filter :check_for_order_contents,   :except => [:thank_you]
  before_filter :configure_countries

  def details

  end

  def update
    order.update_details(permitted_params[:order_basket])
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

  # @todo Do a better job of handling errors that come from authorizing
  def payment_process
    result = payment_provider.confirm_payment_submission(
      request.env["QUERY_STRING"],
      :execute => :authorize,
      :amount => order.total.raw
    )

    @payment = PaymentSubmission.new(result)

    if result.successful? and order.run!(:add, result)
      flash['order'] = session['order'] #keep the order around for the next request only
      session.delete('order')
      redirect_to path(:order_checkout_thank_you, :reference => order.reference)
    else
      render :payment
    end
  end

  def thank_you
    unless flash['order'].blank?
      flash[:order_just_completed] = true

      # Yuck!
      # Keep a record of the order in flash until the user leaves the page - basically, allow refreshes of the thankyou page.
      flash['order'] = flash['order']
      order_from_flash
    end
  end

  private

  def permitted_params
    params.permit(:order_basket => [
      :billing_company, :billing_country, :billing_postcode, :billing_state, :billing_street,
      :billing_city, :email, :gift_message, :is_gift, :name, :phone,
      :shipping_name, :shipping_company, :shipping_city, :shipping_country, :shipping_instructions,
      :shipping_postcode, :shipping_state, :shipping_street, :use_shipping_address, :use_billing_address
    ])
  end

  # This is made annoying by the fact that @order is set by a before filter in the application controller
  # This workaround checks the session dump directly.
  def check_for_order_contents
    if order.empty?
      redirect_to path(:order_basket)
    end
  end

  def configure_countries
    @billable_countries = IslayShop::Engine.config.billable_countries
    @shippable_countries = IslayShop::Engine.config.shippable_countries
  end
end
