class IslayShop::Admin::ManufacturersController < IslayShop::Admin::ApplicationController
  resourceful :manufacturer
  header 'Shop - Manufacturers'
  nav 'islay_shop/admin/shop/nav'

  def index
    @manufacturers = Manufacturer.summary
  end

  def dependencies
    @assets = Asset.order('name')
  end
end

