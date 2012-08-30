class IslayShop::Public::BasketController < IslayShop::Public::ApplicationController
  before_filter :check_for_order, :except => [:clear]

  def contents

  end

  def add
    @order.increment_item(params[:sku_id], params[:quantity])
    store_and_redirect
  end

  def remove
    @order.remove_item(params[:sku_id])
    store_and_redirect
  end

  def update
    @order.update_items(params[:order_basket][:items_attributes].values)
    store_and_redirect
  end

  def destroy_alerts
    @order.destroy_alerts
    store_and_redirect
  end

  def destroy
    session.delete('order')
    bounce_back
  end

  private

  # Checks to see if there is an order in the session. If there is, it loads it
  # without applying promotions. Otherwise it creates a new instance.
  def check_for_order
    @order = if session['order']
      OrderBasket.load(session['order'], false)
    else
      OrderBasket.new
    end
  end

  # Dumps a JSON representation of an order into the user's session, then
  # redirects them to either the originating URL or another URL specifed
  # via the params.
  def store_and_redirect
    session['order'] = @order.dump
    bounce_back
  end
end
