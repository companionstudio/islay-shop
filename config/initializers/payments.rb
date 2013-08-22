# Grab the payment configuration details from the environment, if available.
%w(merchant_id public_key private_key).each do |name|
  var = :"braintree_#{name}"
  if Settings.defined?(:shop, var)
    IslayShop::Engine.config.payments[name.to_sym] = Settings.for(:shop, var)
  end
end
