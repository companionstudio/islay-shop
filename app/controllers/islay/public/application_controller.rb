class Islay::Public::ApplicationController
  before_filter :load_order
  attr_reader :order

  private

  def load_order
    if session['order']
      @order = OrderBasket.load(JSON.parse(session['order']))
    end
  end
end
