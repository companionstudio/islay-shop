Sku.blueprint do
  volume        { rand(750) + 100 }
  published     { true }
  price         { rand(90) + 4 }
  batch_size    { 12 }
  batch_price   { object.price - rand(3) }
  published     { true }
  published_at  { Time.now }
  stock_level   { rand(20000) + 1 }
end
