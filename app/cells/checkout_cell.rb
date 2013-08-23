class CheckoutCell < Cell::Rails
  include IslayShop::Payments
  helper IslayShop::Public::PromotionDisplayHelper
  helper_method :parent_controller, :input_opts, :select_opts

  # Seriously Ruby, screw you for making me do this. Y U NO NO DATES?
  MONTH_NAMES = %w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec).freeze
  MONTHS = MONTH_NAMES.each_with_index.map do |m, i|
    index = i + 1
    ["#{index} - #{m}", index]
  end.freeze

  def basket(order)
    @order = order
    fetch_promotions
    render
  end

  def form(order)
    @order = order
    render
  end

  # Renders a payment form for collecting details and sending them to the
  # nominated payment provider. This is handled via the IslayShop::Payments
  # module and the SpookAndPay library.
  #
  # @param OrderBasket order
  # @param PaymentSubmission payment
  # @return String
  def payment(order, payment)
    @order = order
    @payment = payment

    @config = payment_provider.prepare_payment_submission(
      :authorize,
      public_order_checkout_payment_process_url(:host => request.host),
      @order.total
    )

    current = Date.today.year
    @years = (current..(current + 20)).to_a
    @months = MONTHS
    render
  end

  def fetch_promotions
    #Any promotions that can be qualified for at the checkout (code based)
    @checkout_promotions = Promotion.active_code_based

    #Any promotions ready to be applied to the order
    if @order and !@order.pending_promotions.empty?
      @promotions = @order.pending_promotions
    end

  end

  # A convenience helper for generating options for inputs.
  #
  # @param Symbol name
  # @param Hash opts
  # @return Hash
  def input_opts(name, opts = {})
    opts[:input_html] ||= {}
    opts[:input_html][:name] = @config[:field_names][name]
    opts
  end

  def select_opts(name, prompt, collection, opts = {})
    input_opts(name, opts).merge(
      :as => :select, 
      :collection => collection, 
      :include_blank => :placeholder, 
      :prompt => prompt
    )
  end
end
