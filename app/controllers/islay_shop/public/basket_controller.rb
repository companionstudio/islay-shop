class IslayShop::Public::BasketController < IslayShop::Public::ApplicationController
  include IslayShop::ControllerExtensions::Public

  def contents

  end

  def add
    sku = Sku.find(params[:sku_id])
    original_quantity = unpromoted_order.quantity_of_sku(sku)
    requested_quantity = params[:quantity].to_i

    item = unpromoted_order.increment_quantity(sku, requested_quantity)

    # @todo: Implement a messaging system so we can communicate this stuff to the user
    added_quantity = item.quantity - original_quantity

    if request.xhr?
      unpromoted_order.apply_promotions!
      store!

      render :json => {
        :result         => (unpromoted_order.errors.blank? ? 'success' : 'failure'),
        :sku            => params[:sku_id],
        :added          => added_quantity,
        :max_available  => unpromoted_order.find_item(sku).maximum_quantity_allowed - item.quantity,
        :quantity       => unpromoted_order.sku_items.quantity,
        :shipping       => unpromoted_order.shipping_total.to_s,
        :total          => unpromoted_order.total.to_s,
        :errors         => unpromoted_order.errors
      }
    else
      store_and_redirect(:order_item_added, {:message => item.description, :added => added_quantity})
    end
  end

  def remove
    item = unpromoted_order.remove_item(params[:sku_id])
    store_and_redirect(:order_item_removed, {:message => item.sku.long_desc})
  end

  def update
    unless params[:items].blank?
      unpromoted_order.update_quantities(params[:items])
    end

    unless params[:promo_code].blank?
      unpromoted_order.promo_code = params[:promo_code]
    end

    unless params[:billing_postcode].blank?
      unpromoted_order.billing_postcode = params[:billing_postcode]
    end

    store_and_redirect(:order_updated, {:message => "Your order has been updated"})
  end

  def destroy_alerts
    unpromoted_order.destroy_alerts
    store_and_redirect
  end

  def destroy
    session.delete('order')
    bounce_back
  end

  private

  # Dumps a JSON representation of an order into the user's session.
  #
  # @return Hash
  def store!
    session['order'] = unpromoted_order.dump
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
