class CreditCardPayment < ActiveRecord::Base
  belongs_to  :order
  has_many    :transactions, :class_name => 'CreditCardTransaction'
end
