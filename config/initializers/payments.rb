if Settings.defined?(:shop, :payment_provider)
  IslayShop::Engine.config.payments[:provider] = Settings.for(:shop, :payment_provider).to_sym

  if Settings.defined?(:shop, :currency_code)
    IslayShop::Engine.config.payments[:currency_code] = Settings.for(:shop, :currency_code)
  else
    IslayShop::Engine.config.payments[:currency_code] = 'AUD'
  end

  case Settings.for(:shop, :payment_provider)
  when'braintree'
    %w(env merchant_id public_key private_key).each do |name|
      var = :"braintree_#{name}"
      IslayShop::Engine.config.payments[name.to_sym] = Settings.for(:shop, var)
    end
  when 'spreedly'
    %w(environment_key access_secret gateway_token).each do |name|
      var = :"spreedly_#{name}"
      IslayShop::Engine.config.payments[name.to_sym] = Settings.for(:shop, var)
    end
  end
end
