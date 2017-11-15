module OfferOrdersConcern
  extend ActiveSupport::Concern

  # map member fields to order fields
  FIELD_MAPPING = {
    phone:                :phone,
    email:                :email,
    day_of_birth:         :day_of_birth,
    month_of_birth:       :month_of_birth,
    year_of_birth:        :year_of_birth,

    billing_first_name:   :first_name,
    billing_last_name:    :last_name,

    shipping_address:     :billing_company,
    billing_address:      :billing_address,
    billing_city:         :billing_city,
    billing_state:        :billing_state,
    billing_postcode:     :billing_postcode,
    billing_country:      :billing_country,

    use_shipping_address: :use_shipping_address,
    shipping_first_name:  :first_name,
    shipping_last_name:   :last_name,

    shipping_address:     :shipping_company,
    shipping_address:     :shipping_address,
    shipping_city:        :shipping_city,
    shipping_state:       :shipping_state,
    shipping_postcode:    :shipping_postcode,
    shipping_country:     :shipping_country
  }.freeze

  def generate_member_order!(member)
    raise "This is not an active member" unless member.present? and member.active?
    raise "This member doesn't have an active payment method" unless member.default_payment_method.present?

    ActiveRecord::Base.transaction do

      order = Order.new

      order.name  = member.name
      order.phone = member.phone
      order.email = member.email

      order.billing_street    = member.billing_address.street
      order.billing_city      = member.billing_address.city
      order.billing_postcode  = member.billing_address.postcode
      order.billing_state     = member.billing_address.state
      order.billing_country   = member.billing_address.country

      order.shipping_street   = member.shipping_address.street
      order.shipping_city     = member.shipping_address.city
      order.shipping_postcode = member.shipping_address.postcode
      order.shipping_state    = member.shipping_address.state
      order.shipping_country  = member.shipping_address.country

      order.build_offer_order(offer: self)
      order.build_member_order(member: member)

      # order.payment_method = member.default_payment_method
      #
      # order.apply_payment_method(payment_method)

      offer_items.each do |offer_item|
        order.set_quantity_and_price(offer_item.sku, offer_item.quantity, sku_unit_price * offer_item.quantity)
      end

      order.save!

      binding.pry
    end

    order
  end

end
