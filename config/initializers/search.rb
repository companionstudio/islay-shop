Islay::Engine.searches do |config|
  config.search(:order) do |o|
    {
      o.name => 'A',
      o.shipping_name => 'A',
      o.reference => 'A',
      o.tracking_reference => 'B',
      o.email => 'B',
      o.phone => 'B',
      o.billing_street => 'C',
      o.billing_city => 'C',
      o.billing_postcode => 'C',
      o.shipping_street => 'C',
      o.shipping_city => 'C',
      o.shipping_postcode => 'C'
    }
  end

  config.search(:manufacturer) do |m|
    {m.name => 'A'}
  end

  config.search(:product_category) do |c|
    {c.name => 'A'}
  end

  config.search(:product_range) do |r|
    {r.name => 'A'}
  end

  config.search(:sku) do |sku|
    {
      sku.name         => 'A',
      sku.product.name => 'A'
    }
  end

  config.search(:product) do |product|
    terms = product.skus.reduce({}) do |h, s|
      h[s.name] = 'C'
      h
    end

    terms.merge({
      product.name => 'A',
      product.description => 'C'
    })
  end

  config.depends(:sku, :product)
  config.depends(:product, :skus)
end

