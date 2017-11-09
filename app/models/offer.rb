class Offer < ActiveRecord::Base
  validations_from_schema

  include PgSearch
  multisearchable :against => [:name]

  extend FriendlyId
  friendly_id :name, :use => [:slugged, :finders]

  has_many :offer_items
  has_many :offer_orders
  has_many :orders, through: :offer_orders

  accepts_nested_attributes_for :offer_items, allow_destroy: true, reject_if: lambda {|a| a[:sku_id].blank?}

  def self.filtered(filter)
    case filter
    when 'running' then where.not(:status => 'running')
    when 'finished' then where.not(:status => 'finished')
    when 'future' then where.not(:status => 'active')
    else all
    end
  end

  # Returns a scope that sorts the results by the provided field. This behaves
  # close to ::order except that it defaults to sorting by :name.
  #
  # @param [String, nil] sort
  def self.sorted(sort)
    order(sort || :name)
  end

  def destroyable?
    true
  end

  def candidates
    Member.active.with_payment_method
  end

   # Returns a stubbed out offer item which serves as a 'template' for
   # generating new items.
   #
   # @return OfferItem
   def offer_item_template(quantity = 1)
     OfferItem.new(:quantity => quantity)
   end

   alias_method :original_offer_items_attributes=, :offer_items_attributes=
   # Massage incoming item params before saving
   #
   # @return nil
   def offer_items_attributes=(vals)
     vals.each do |_, val|
        val['_destroy'] = true if val['quantity'].blank? or val['quantity'] == '0'
     end
     binding.pry
     self.original_offer_items_attributes = vals
   end

end
