ProductCategory.blueprint do
  name          { Faker::Lorem.words.join(' ').capitalize }
  description   { Faker::Lorem.sentences.join(' ') }
  published     { true }

  products rand(9) + 1
end
