class IslayShop::Public::BasketController < IslayShop::Public::ApplicationController

  def contents

  end

  def add
    item = @order.increment_item(params[:sku_id], params[:quantity])
    if request.xhr?
      store!
      render :json => {
        :result => (@order.errors.blank? ? 'success' : 'failure'),
        :sku => params[:sku_id],
        :added => params[:quantity],
        :quantity => @order.unit_total_quantity,
        :shipping => @order.formatted_shipping_total,
        :total => @order.formatted_total,
        :errors => @order.errors
      }
    else
      store_and_redirect(:order_item_added, {:message => item.description, :added => params[:quantity]})
    end
  end

  def remove
    item = @order.remove_item(params[:sku_id])
    store_and_redirect(:order_item_removed, {:message => item.sku.long_desc})
  end

  def update
    
    @order.update_items(params[:order_basket][:items_attributes].values)

    #Apply a code based promotion if it's supplied:
    @code_promotions = !Promotion.active_code_based.empty?

    if params[:order_basket][:promo_code] and @code_promotions

      @order.promo_code = params[:order_basket][:promo_code]
      results = Promotion.check_qualification(@order)

      if results.none?
        message = if results.partial_success?
          messages = results.partially_successful.messages
          if messages.include?(:invalid_code)
            :invalid_code
          end
        else
          messages = results.failures.messages
          :invalid_code if messages.include?(:invalid_code) 
        end
        @order.promo_code = nil
        flash[:promotion_code_result] = message
      elsif results.any?
        applied_promos = results.successful.map(){|r| r.promotion.description}.join(', ')
        flash[:promotion_code_result] = "Thank you, your code was applied."
      end
    end

    store_and_redirect(:order_updated, {:message => "Your order has been updated"})
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

  # Dumps a JSON representation of an order into the user's session
  def store!
    session['order'] = @order.dump
    retrieve_order #Temporary: until we complete work on the full promotions engine. 
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
    if @order.empty?
      redirect_to path(:order_basket)
    else
      bounce_back
    end
  end
end
