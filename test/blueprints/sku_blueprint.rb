Sku.blueprint do
  published     { true }
  price         { rand(40) + 1 }
  published     { true }
  published_at  { Time.now }
  stock_level   { rand(120) + 1 }
end
