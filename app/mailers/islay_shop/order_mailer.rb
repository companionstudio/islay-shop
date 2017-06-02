class IslayShop::OrderMailer < ActionMailer::Base
  helper '/islay/public/application'

  default :from => Settings.for(:shop, :email),
          :bcc => Settings.for(:shop, :email),
          :charset => 'UTF-8'

  layout  'mail'

  def thank_you(order)
    @order = order
    mail(
      :to => order.email,
      :subject => "#{Settings.for(:islay, :name)} - Thank you for your order",
    ) do |format|
      format.html {with_inline_styles render}
    end
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

  def with_inline_styles(html)
    Premailer.new(html, :with_html_string => true).to_inline_css
  end
end
