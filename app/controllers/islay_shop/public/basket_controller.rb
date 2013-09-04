class IslayShop::Public::BasketController < IslayShop::Public::ApplicationController
  include IslayShop::ControllerExtensions::Public

  def contents

  end

  def add
    sku = Sku.find(params[:sku_id])
    item = order.increment_quantity(sku, params[:quantity].to_i)

    if request.xhr?
      store!
      render :json => {
        :result => (order.errors.blank? ? 'success' : 'failure'),
        :sku => params[:sku_id],
        :added => params[:quantity],
        :quantity => order.total_sku_quantity,
        :shipping => order.formatted_shipping_total,
        :total => order.formatted_total,
        :errors => order.errors
      }
    else
      store_and_redirect(:order_item_added, {:message => item.description, :added => params[:quantity]})
    end
  end

  def remove
    item = order.remove_item(params[:sku_id])
    store_and_redirect(:order_item_removed, {:message => item.sku.long_desc})
  end

  def update
    order.update_quantities(params[:items])
    store_and_redirect(:order_updated, {:message => "Your order has been updated"})
  end

  def destroy_alerts
    order.destroy_alerts
    store_and_redirect
  end

  def destroy
    session.delete('order')
    bounce_back
  end

  private

  # Dumps a JSON representation of an order into the user's session
  def store!
    session['order'] = order.dump
  end

  # Dumps a JSON representation of an order into the user's session, then
  # redirects them to either the originating URL or another URL specifed
  # via the params.
  #
  # @param Symbol key
  # @param String note
  #
  def store_and_redirect(key = nil, note = nil)
    flash[key] = note if key and note
    store!
    bounce_back
  end
end
