module IslayShop::Payments
  # Initializes a provider instance.
  #
  # @return SpookAndPay::Providers::Base
  def payment_provider
    @payment_provider ||= case IslayShop::Engine.config.payments.provider
    when :braintree
      SpookAndPay::Providers::Braintree.new(
        IslayShop::Engine.config.payments.env.to_sym,
        :merchant_id  => IslayShop::Engine.config.payments.merchant_id,
        :public_key   => IslayShop::Engine.config.payments.public_key,
        :private_key  => IslayShop::Engine.config.payments.private_key
      )
    when :spreedly
      SpookAndPay::Providers::Spreedly.new(
        Rails.env,
        :environment_key  => IslayShop::Engine.config.payments.environment_key,
        :access_secret    => IslayShop::Engine.config.payments.access_secret,
        :gateway_token    => IslayShop::Engine.config.payments.gateway_token,
        :currency_code    => IslayShop::Engine.config.payments.currency_code
      )
    end
  end
end
