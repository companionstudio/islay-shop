class IslayShop::Admin::StockLevelsController < IslayShop::Admin::ApplicationController
  header 'Shop - Stock Levels'
  nav 'islay_shop/admin/shop/nav'

  def index
    @skus = Sku.full_summary.filter(params[:filter]).sorted(params[:sort])
  end

  def update
    Sku.update_stock!(params[:stock_levels])
    redirect_to request.referrer
  end
end
