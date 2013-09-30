class IslayShop::Admin::ManufacturersController < IslayShop::Admin::ApplicationController
  resourceful :manufacturer
  header 'Catalogue - Manufacturers'
  nav_scope :catalogue

  def index
    @manufacturers = Manufacturer.summary
  end

  def dependencies
    @assets = Asset.order('name')
  end
end

