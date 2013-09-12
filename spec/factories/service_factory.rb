FactoryGirl.define do
  factory :service_price_point do
    current true
    valid_from { Time.now.ago(3.weeks) }
  end

  factory :service do
    factory :shipping_service do
      name "Shipping"
      deletable false
      key "shipping"

      after(:build) do |s|
        s.price_points << FactoryGirl.build(:service_price_point, :price => '15')
      end
    end

    factory :wrapping_service do
      name "Gift Wrapping"

      after(:build) do |s|
        s.price_points << FactoryGirl.build(:service_price_point, :price => '5')
      end
    end
  end
end
