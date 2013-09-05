FactoryGirl.define do
  factory :product_category do
    name        { Faker::Lorem.words.join }
    description { Faker::Lorem.paragraph }
  end
end

