class OrderBasket < Order
  include OrderPromotionConcern

  after_create :send_thank_you_mail

  # Persists an order and purchases the stock.
  #
  # @param SpookAndPay::Result result
  # @return [true, false]
  def process_add!(result)
    self.payment = create_payment(result)

    skus = Hash[*sku_items.map {|i| [i.sku_id, i.quantity]}.flatten]
    Sku.purchase_stock!(skus)
    next!("Authorizing #{formatted_total}")
  end

  #Process the order with a purchase already made
  def process_purchase!(result)
    self.payment = create_payment(result)

    if payment.status.in?(%w{settling settled})
      skus = Hash[sku_items.map {|i| [i.sku_id, i.quantity]}]
      Sku.purchase_stock!(skus)

      next!("Charged #{formatted_total}")
    else
      fail!("Could not take payment because of a problem with the payment provider")
    end
  end

  # An alias for #attributes= which also triggers #calculate_totals. This is
  # mainly useful when things like the shipping service rely on address details
  # for their calculations.
  #
  # @param Hash details
  # @return nil
  def update_details(details)
    self.attributes = details
    calculate_totals
    nil
  end

  private

  def create_payment(result)
    OrderPayment.new(
      :name               => result.credit_card.name,
      :number             => result.credit_card.number,
      :expiration_month   => result.credit_card.expiration_month,
      :expiration_year    => result.credit_card.expiration_year,
      :provider_name      => IslayShop::Engine.config.payments.provider,
      :provider_token     => result.transaction.id,
      :status             => result.transaction.status,
      :card_type          => result.credit_card.card_type
    )
  end

  # Sends the thank you email when the order is successfully created
  def send_thank_you_mail
    IslayShop::OrderMailer.thank_you(self).deliver
  end
end
