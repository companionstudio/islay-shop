class IslayShop::Admin::SkuPricePointsController < IslayShop::Admin::ApplicationController
  header 'Shop - Products'
  nav 'islay_shop/admin/shop/nav'

  def index
    @product = Product.find(params[:product_id])
    @price_points = @product.price_points.summary.order("current DESC, valid_from DESC")
  end
end
