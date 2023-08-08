class IslayShop::Admin::StockLevelsController < IslayShop::Admin::ApplicationController
  helper IslayShop::Admin::CatalogueHelper
  header 'Catalogue - Stock Levels'
  nav_scope :catalogue

  def index
    @skus = Sku.filter(permitted_params[:filter]).sorted(permitted_params[:sort]).full_summary
  end

  def update
    Sku.update_stock!(permitted_params[:stock_levels].to_h)
    flash[:notice] = "Stock levels were updated successfully."
    redirect_to request.referrer
  end

  private

  def permitted_params
    params.permit!
  end
end
