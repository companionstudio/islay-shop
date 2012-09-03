class IslayShop::OrderMailer < ActionMailer::Base
  def thank_you(order)
    @order = order
    mail(
      :to => order.email,
      :subject => 'Thank you for your order'
    )
  end

  def shipped(order)
    @order = order
    mail(
      :to => order.email,
      :subject => 'Your order is on its way'
    )
  end

  def cancelled(order)
    @order = order
    mail(
      :to => order.email,
      :subject => 'Your order has been cancelled'
    )
  end
end
