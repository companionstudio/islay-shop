class CheckoutCell < Cell::Rails
  helper IslayShop::Public::PromotionDisplayHelper
  helper_method :parent_controller

  # Seriously Ruby, screw you for making me do this. Y U NO NO DATES?
  MONTH_NAMES = %w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec).freeze
  MONTHS = MONTH_NAMES.each_with_index.map do |m, i|
    index = i + 1
    ["#{index} - #{m}", index]
  end.freeze

  def basket(order)
    @order = order
    @order.apply_promotions!
    fetch_promotions
    render
  end

  def form(order)
    @order = order
    render
  end

  def spreedly_payment(order, payment)
    @order = order
    @payment = payment

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
end
