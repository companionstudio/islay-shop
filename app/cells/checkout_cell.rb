class CheckoutCell < Cell::Rails
  # Seriously Ruby, screw you for making me do this. Y U NO NO DATES?
  MONTH_NAMES = %w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec).freeze
  MONTHS = MONTH_NAMES.each_with_index.map do |m, i|
    index = i + 1
    ["#{index} - #{m}", index]
  end.freeze

  def basket(order)
    @order = order
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
end
