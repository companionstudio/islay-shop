FactoryGirl.define do
  factory :product do
    name        { Faker::Lorem.words.join }
    description { Faker::Lorem.paragraph }
    category    { create(:product_category) }
    published   true

    factory :volume_discounted_product do
      after(:build) do |product, evaluator|
        product.skus << FactoryGirl.build(:liquid_sku, :price_points => [
          FactoryGirl.build(:single_sku_price_point),
          FactoryGirl.build(:boxed_sku_price_point),
          FactoryGirl.build(:boxed_sku_price_point, :volume => 12, :price => '4.75'),
          FactoryGirl.build(:bracketed_sku_price_point)
        ])
      end
    end
  end

  factory :sku do
    stock_level { (rand(10) + 1) * 10 }

    factory :liquid_sku do
      volume { [100, 150, 200, 250, 500, 750, 1000].sample }
    end

    factory :solid_sku do
      weight { [100, 150, 200, 250, 500, 750, 1000].sample }
    end
  end

  factory :sku_price_point do
    current true
    valid_from { Time.now }

    factory :single_sku_price_point do
      volume 1
      mode 'single'
      price '4.95'
    end

    factory :boxed_sku_price_point do
      volume 6
      mode 'boxed'
      price '4.325'
    end

    factory :bracketed_sku_price_point do
      volume 100
      mode 'bracketed'
      price '3.95'
    end
  end
end
