OrderItem.blueprint do
  sku       { pick(Sku) }
  quantity  { rand(7) + 1 }
end
