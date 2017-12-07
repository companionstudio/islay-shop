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
      format.html {with_inline_styles render}
    end
  end

  def shipped(order)
    return if Settings.for(:shop, :disable_order_shipping_mail)

    @order = order
    mail(
      :to => order.email,
      :subject => "#{Settings.for(:islay, :name)} - Your order is on its way"
    )
  end

  def cancelled(order)
    return if Settings.for(:islay_shop, :disable_order_cancelled_mail)
    
    @order = order
    mail(
      :to => order.email,
      :subject => "#{Settings.for(:islay, :name)} - Your order has been cancelled"
    )
  end

  def with_inline_styles(html)
    Premailer.new(html, :with_html_string => true).to_inline_css
  end
end
