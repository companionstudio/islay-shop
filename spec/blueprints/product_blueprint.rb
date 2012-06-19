Product.blueprint do
  name          { Faker::Lorem.words.join(' ').capitalize }
  published     { true }
  published_at  { Time.now }
  description   { Faker::Lorem.sentences.join(' ') }

  skus rand(4) + 1
end
