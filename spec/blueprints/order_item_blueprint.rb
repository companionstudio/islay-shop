OrderItem.blueprint do
  sku       { pick(Sku) }
  quantity  { rand(13) + 1 }
end
