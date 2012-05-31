class CreditCardTransaction < ActiveRecord::Base
  belongs_to :credit_card_payment
end
