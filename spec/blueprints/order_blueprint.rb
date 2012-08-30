OrderProcess.blueprint do
  items rand(5) + 1

  name              { Faker::Name.name }
  email             { Faker::Internet.email(object.name) }
  phone             { Faker::PhoneNumber.phone_number }
  billing_street    { Faker::Address.street_address }
  billing_city      { Faker::Address.city }
  billing_state     { Faker::Address.us_state }
  billing_postcode  { Faker::Address.zip_code }
  billing_country   { 'AU' }
  shipping_total    { 0 }

  credit_card_payment
end
