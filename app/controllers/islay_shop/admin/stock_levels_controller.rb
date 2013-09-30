class IslayShop::Admin::StockLevelsController < IslayShop::Admin::ApplicationController
  helper IslayShop::Admin::CatalogueHelper
  header 'Catalogue - Stock Levels'
  nav_scope :catalogue

  def index
    @skus = Sku.full_summary.filter(params[:filter]).sorted(params[:sort])
  end

  def update
    Sku.update_stock!(params[:stock_levels])
    redirect_to request.referrer
  end
end
