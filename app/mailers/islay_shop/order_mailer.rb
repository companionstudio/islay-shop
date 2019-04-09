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

  def billing_failed(order)
    @order = order
    mail(
      :to => order.email,
      :subject => "We couldn't bill your order"
    )
  end

  def with_inline_styles(html)
    Premailer.new(html, :with_html_string => true).to_inline_css
  end

	def mail_asset_url(path)
    if Rails.env == "development"
      Rails.application.assets.find_asset(path)
    elsif Rails.env == "production"
      Rails.application.assets_manifest.find_sources("#{path}.css").first
    end
  end

  helper_method :mail_asset_url
end
