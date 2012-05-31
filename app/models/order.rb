class Order < ActiveRecord::Base
  belongs_to  :person
  belongs_to  :promotion
  has_many    :items, :class_name => 'OrderItems'
  has_one     :credit_card_payment
end