CreditCardPayment.blueprint do

  amount      { rand(100.00) + 1 }
  first_name  { Faker::Name.first_name }
  last_name   { Faker::Name.last_name }
  number      { 'XXXX-XXXX-XXXX-1111' }
  month       { 10 }
  year        { 2017 }
  gateway_id  { 'kjse0934kje0934iuhsjkkjdsf0' }
  gateway_expiry { Time.now.next_month }
end
