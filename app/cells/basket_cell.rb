class BasketCell < Cell::Rails
  helper_method :parent_controller

  def detailed
    load_order
    render
  end

  def short
    load_order
    render
  end

  def summary
    load_order
    render
  end

  private

  def load_order
    @order = if session['order']
      OrderBasket.load(session['order'])
    else
      OrderBasket.new
    end
  end
end
