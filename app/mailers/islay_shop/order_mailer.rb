class IslayShop::OrderMailer < ActionMailer::Base
  helper '/islay/public/application'

  default :from => Settings.for(:shop, :email),
          :bcc => Settings.for(:shop, :email),
          :charset => 'UTF-8'

  layout  'mail'

  def thank_you(order)
    return if Settings.for(:shop, :disable_order_thank_you_mail)

    @order = order

    mail(
      :to => order.email,
      :subject => "#{Settings.for(:islay, :name)} - Thank you for your order",
    ) do |format|
      format.html {render}
    end
  end

  def shipped(order)
    return if Settings.for(:shop, :disable_order_shipping_mail)

    @order = order
    mail(
      :to => order.email,
      :subject => "#{Settings.for(:islay, :name)} - Your order is on its way"
    ) do |format|
      format.html {render}
    end
  end

  def cancelled(order)
    return if Settings.for(:shop, :disable_order_cancelled_mail)

    @order = order
    mail(
      :to => order.email,
      :subject => "#{Settings.for(:islay, :name)} - Your order has been cancelled"
    ) do |format|
      format.html {render}
    end
  end
end
