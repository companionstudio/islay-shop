Sku.blueprint do
  published     { true }
  price         { rand(90) + 1 }
  published     { true }
  published_at  { Time.now }
  stock_level   { rand(20000) + 1 }
end
