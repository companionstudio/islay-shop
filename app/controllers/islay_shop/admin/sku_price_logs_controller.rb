class IslayShop::Admin::SkuPriceLogsController < IslayShop::Admin::ApplicationController
  header 'Shop - Products'
  nav 'islay_shop/admin/shop/nav'

  def index
    @product = Product.find(params[:product_id])
    @price_logs = @product.price_logs.summary
  end
end
