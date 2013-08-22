module IslayShop::Payments
  # Initializes a provider instance.
  #
  # @return SpookAndPay::Providers::Base
  def payment_provider
    @payment_provider ||= SpookAndPay::Providers::Braintree.new(
      :development,
      :merchant_id  => IslayShop::Engine.config.payments.merchant_id,
      :public_key   => IslayShop::Engine.config.payments.public_key,
      :private_key  => IslayShop::Engine.config.payments.private_key
    )
  end
end
