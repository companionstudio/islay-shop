class OrderProcess < Order
  private

  def process_add!(token)
    self.credit_card_payment = CreditCardPayment.new(:order => self, :token => token, :amount => total)
    if valid? and credit_card_payment.authorize!
      Public::OrderMailer.pending(self).deliver
      next!
    else
      fail!
    end
  end

  def process_capture!
    if credit_card_payment.capture!
      next!
    else
      fail!
    end
  end

  def process_cancellation!
    if credit_card_payment.cancel!
      Public::OrderMailer.cancelled(self).deliver
      next!
    else
      fail!
    end
  end

  def process_shipping!
    Public::OrderMailer.shipped(self).deliver
    next!
  end
end
