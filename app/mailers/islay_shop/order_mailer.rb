class IslayShop::OrderMailer < ActionMailer::Base
  default :from => Settings.for(:shop, :email)

  def thank_you(order)
    @order = order
    mail(
      :to => order.email,
      :subject => "#{Settings.for(:islay, :name)} - Thank you for your order"
    )
  end

  def shipped(order)
    @order = order
    mail(
      :to => order.email,
      :subject => "#{Settings.for(:islay, :name)} - Your order is on its way"
    )
  end

  def cancelled(order)
    @order = order
    mail(
      :to => order.email,
      :subject => "#{Settings.for(:islay, :name)} - Your order has been cancelled"
    )
  end
end
