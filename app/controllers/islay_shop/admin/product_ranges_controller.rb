class IslayShop::Admin::ProductRangesController < IslayShop::Admin::ApplicationController

  resourceful :product_range
  header 'Catalogue - Product Ranges'
  nav_scope :catalogue

  private

  def permitted_params
    params.permit(:product_range => [:name, :description])
  end
end
