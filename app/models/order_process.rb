class OrderProcess < Order
  before_create :store_reference

  private

  def process_add!
    skus = Hash[sku_items.map {|i| [i.sku_id, i.quantity]}]
    Sku.purchase_stock!(skus)
    next!
  end

  # Captures the funds that were previously authorized.
  #
  # @return Boolean
  def process_billing!
    action = if payment.status == 'future'
      payment.purchase!
    else
      payment.capture!
    end

    if action
      next!("Charged #{formatted_total}")
    else
      fail!("Could not take payment due to a problem with the payment provider")
    end
  end

  # Cancels an order. This will release authorization or credit payments, then
  # return all the SKUs from the order back into stock.
  #
  # @return Boolean
  def process_cancellation!
    if payment.settled?
      # If we have the money, refund it.
      if payment.refund!
        return_stock
        IslayShop::OrderMailer.cancelled(self).deliver
        next!("Credited #{formatted_total}")
      else
        fail!("Could not refund payment due to a problem with the payment provider")
      end
    else
      # If the payment provider supports voiding, void
      if payment.can_void?
        if payment.void!
          return_stock
          IslayShop::OrderMailer.cancelled(self).deliver
          next!("Payment has been voided")
        else
          fail!("Could not void payment due to a problem with the payment provider")
        end
      else
        # Let the authorization expire:
        return_stock
        IslayShop::OrderMailer.cancelled(self).deliver
        next!("Payment can't be voided: the authorization will expire, usually within 7 days.")
      end
    end
  end

  # A helper which will return all the items in this order back into stock.
  #
  # @return Hash
  def return_stock
    skus = Hash[sku_items.map {|i| [i.sku_id, i.quantity]}]
    Sku.return_stock!(skus)
  end

  def process_shipping!
    IslayShop::OrderMailer.shipped(self).deliver
    next!
  end

  # Attempts to generate a reference for the order. Since the reference needs to
  # be unique and is generated rather than being a serial value, we attempt to
  # generate it five times. On failure, we raise an error.
  #
  # @return String
  def store_reference
    5.times do
      self[:reference] = generate_reference
      return reference unless self.class.where(:reference => reference).first
    end

    raise "Could not generate unique reference for order"
  end

  # Generates a reference using the time, and a 6 char hex string.
  #
  # @return String
  def generate_reference
    "#{Time.now.strftime('%y%m')}-#{SecureRandom.hex(3).upcase}"
  end


end
