# Do this because machinist is dumb. Won't let me execute arbitrary code in a
# blueprint. DERP.
OrderItem.class_eval do
  alias_method :update_quantity=, :update_quantity
end

OrderItem.blueprint do
  sku             { pick(Sku) }
  update_quantity { rand(7) + 1 }
end
