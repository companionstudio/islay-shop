CreditCardPayment.class_eval do
  # These are over-ridden here in order to prevent the models from going
  # off and hitting up SpreedlyCore during generation.
  def check_card_number; end
  def set_payment_details; end
end

CreditCardPayment.blueprint do

  amount              { rand(100.00) + 1 }
  first_name          { Faker::Name.first_name }
  last_name           { Faker::Name.last_name }
  number              { 'XXXX-XXXX-XXXX-1111' }
  month               { 10 }
  year                { 2017 }
  verification_value  { 343 }
  gateway_id          { 'kjse0934kje0934iuhsjkkjdsf0' }
  gateway_expiry      { Time.now.next_month }
end
