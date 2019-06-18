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

    billing_company:      :billing_company,
    billing_address:      :billing_address,
    billing_city:         :billing_city,
    billing_state:        :billing_state,
    billing_postcode:     :billing_postcode,
    billing_country:      :billing_country,

    use_shipping_address: :use_shipping_address,
    shipping_first_name:  :first_name,
    shipping_last_name:   :last_name,

    shipping_company:     :shipping_company,
    shipping_address:     :shipping_address,
    shipping_city:        :shipping_city,
    shipping_state:       :shipping_state,
    shipping_postcode:    :shipping_postcode,
    shipping_country:     :shipping_country
  }.freeze

  class OrderGenerationError < StandardError
    def initialize(event, status, check)
      @event = event
      @status = status
      @check = check
    end

    def to_s
      "The event '#{@event}' can't be run while in the '#{@status}' status. Reason: #{@check[:reason]}"
    end
  end

  def generate_orders!(*member_ids)
    members = if member_ids.present?
      candidates.where(id: member_ids)
    else
      candidates
    end

    members.each do |member|
      generate_member_order!(member, default_quantity) unless member.offer_orders.find_by(offer_id: id).present?
    end
  end

  def generate_order_items(order, multiplier)
    order.items.delete_all

    offer_items.each do |offer_item|
      order.set_quantity(offer_item.sku, offer_item.quantity * multiplier)
    end
  end

  def generate_member_order!(member, multiplier)
    raise "This is not an active member" unless member.present? and member.active?
    raise "This member already has an order for this offer" if member.offer_orders.where(offer_id: id).present?
    raise "Quantity multiplier must be between #{min_quantity} and #{max_quantity}" if max_quantity and !multiplier.between?(min_quantity, max_quantity)
    raise "Quantity multiplier must be at least #{min_quantity}" if !max_quantity and multiplier < min_quantity

    ActiveRecord::Base.transaction do

      order = Order.new

      order.status = 'pending'

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

      # Add a payment record
      generate_payment(member, order)

      # Items go in at their standard retail price
      generate_order_items(order, multiplier)

      # Check shipping so we can add an order level adjustment on the price
      order.calculate_shipping

      # Override the total to set the price to the offer price
      order.set_manual_order_total(price * multiplier, 'offer')

      # Run the total calculation to finalise the adjustments
      order.calculate_totals

      order.logs.build(:action => 'add', :notes => "Created order for offer: #{name}")
      order.save!

      offer_order = OfferOrder.create(offer: self, order: order, quantity_multiplier: multiplier)
      member_order = MemberOrder.create(order: order, member: member)

      order
    end
  end

  # Generates the payment for the order, based on the member's default method
  def generate_payment(member, order)
    payment_method = member.default_payment_method

    if payment_method.present? and !payment_method.expired?

      payment_provider = case payment_method.class.name.split('::').first.downcase
      when 'braintree' then :braintree
      when 'spreedly'  then :spreedly
      else payment_method.class.name.split('::').first.to_sym
      end

      order.build_payment(provider_name: payment_provider, card_type: payment_method.card_type, status: 'future', provider_token: payment_method.token, number: payment_method.masked_number, expiration_month: payment_method.expiration_month, expiration_year: payment_method.expiration_year)

    else
      # Something is wrong with the payment details. Still generate the order, but log the issue
      if payment_method.blank?
        order.logs.build(action: 'Payment', succeeded: false, notes: "This member doesn't have an active payment method.")
      elsif payment_method.expired?
        order.logs.build(action: 'Payment', succeeded: false, notes: "This member's credit card has expired.")
      end
    end
  end

  def regenerate_payment!(member, order)
    if order.payment.present?
      order.payment.update_column(:status, 'failed')
      order.reload
      order.logs.build(action: 'Payment', succeeded: true, notes: "Recreated order payment with new details.")
    end

    generate_payment(member, order)
    order.save!
  end

  def regenerate_member_order!(member, multiplier)
    offer_order_set = member.offer_orders.where(offer_id: id)
    offer_order_set.each{|oo|oo.order.delete}
    offer_order_set.delete_all

    generate_member_order!(member, multiplier)
  end

  # Regenerate the items with the multiplier,
  def regenerate_order_items!(order, multiplier)
    generate_order_items(order, multiplier)# Check shipping so we can add an order level adjustment on the price

    order.calculate_shipping

    # Override the total to set the price to the offer price
    order.set_manual_order_total(price * multiplier, 'offer')

    # Run the total calculation to finalise the adjustments
    order.calculate_totals

    order.logs.build(:action => 'update', :notes => "Updated quantities for offer: #{name}")
    order.save!
  end

  def skip!(member)
    offer_order_set = member.offer_orders.where(offer_id: id)
    offer_order_set.each do |offer_order|
      processor = OrderProcess.from_order offer_order.order
      processor.run! :cancel
    end
  end

end
