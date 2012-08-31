class CheckoutCell < Cell::Rails
  # Seriously Ruby, screw you for making me do this. Y U NO NO DATES?
  MONTH_NAMES = %w(January Febuary March April May June July August September October November December).freeze
  MONTHS = MONTH_NAMES.each_with_index.map do |m, i|
    index = i + 1
    month = index < 10 ? "0#{index}" : index
    ["#{month} - #{m}", month]
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
