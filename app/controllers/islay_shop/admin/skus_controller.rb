class IslayShop::Admin::SkusController < IslayShop::Admin::ApplicationController
  resourceful :sku, :parent => :product
  header 'Shop'
  nav 'islay_shop/admin/shop/nav'

  private

  def redirect_for(record)
    path(@product)
  end

  def destroy_redirect_for(record)
    path(@product)
  end
end
