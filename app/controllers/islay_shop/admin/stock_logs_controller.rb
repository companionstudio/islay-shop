class IslayShop::Admin::StockLogsController < IslayShop::Admin::ApplicationController
  header 'Shop - Products'
  nav 'islay_shop/admin/shop/nav'

  def index
    @product = Product.find(params[:product_id])
    @stock_logs = @product.stock_logs.summary
  end
end
