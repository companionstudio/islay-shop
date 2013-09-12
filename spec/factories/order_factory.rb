FactoryGirl.define do
  factory :order do
    name              { Faker::Name.name }  
    billing_street    { Faker::Address.street_address } 
    billing_state     { Faker::AddressAU.state_abbr } 
    billing_city      { Faker::AddressAU.city }
    billing_postcode  { Faker::AddressAU.postcode }
    billing_country   'AU'
    phone             { Faker::PhoneNumberAU.mobile_phone_number }
    email             { Faker::Internet.email(name) }
  end
end
