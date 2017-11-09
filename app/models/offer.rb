class Offer < ActiveRecord::Base
  validations_from_schema

  include PgSearch
  multisearchable :against => [:name]

  extend FriendlyId
  friendly_id :name, :use => [:slugged, :finders]

  has_many :offer_items
  has_many :offer_orders
  has_many :orders, through: :offer_orders

  before_save :check_items

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

   # Returns a stubbed out offer item which serves as a 'template' for
   # generating new items.
   #
   # @return OfferItem
   def offer_item_template(quantity = 1)
     OfferItem.new(:quantity => quantity)
   end

   # This is a no-op. It just allows us to use the offer_item_template in
   # forms.
   #
   # @return nil
   # def new_offer_item=(vals)
   #   nil
   # end

   def check_items
     binding.pry
   end

end
