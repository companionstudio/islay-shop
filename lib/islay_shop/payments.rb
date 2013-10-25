module IslayShop::Payments
  # Initializes a provider instance.
  #
  # @return SpookAndPay::Providers::Base
  # @todo In the future, this should handle different providers based on config
  def payment_provider
    @payment_provider ||= SpookAndPay::Providers::Braintree.new(
      IslayShop::Engine.config.payments.env.to_sym,
      :merchant_id  => IslayShop::Engine.config.payments.merchant_id,
      :public_key   => IslayShop::Engine.config.payments.public_key,
      :private_key  => IslayShop::Engine.config.payments.private_key
    )
  end
end
