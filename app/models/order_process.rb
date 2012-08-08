class OrderProcess < Order
  private

  def process_add!
    skus = Hash[items.map {|i| [i.sku_id, i.quantity]}]
    Sku.purchase_stock!(skus)
    next!
  end

  def process_billing!
    next!
  end

  def process_cancellation!
    skus = Hash[items.map {|i| [i.sku_id, i.quantity]}]
    puts skus.inspect
    Sku.return_stock!(skus)
    next!
  end

  def process_shipping!
    next!
  end
end
