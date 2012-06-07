# Default, base blueprint
Promotion.blueprint do
  name     { Faker::Lorem.words.capitalize }
  start_at { Time.now }
  end_at   { -30.days.ago }
end

Promotion.blueprint(:quantity_condition) do
  condition { PromotionQuantityCondition.make }
end

Promotion.blueprint(:spend_condition) do

end

Promotion.blueprint(:bonus_effect) do

end

Promotion.blueprint(:shipping_effect) do

end

# discount effect
# membership condition
