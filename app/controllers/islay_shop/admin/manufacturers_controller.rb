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

  private

  def permitted_params
    params.permit(:manufacturer => [:name, :description, :published, :asset_ids])
  end
end
