class IslayShop::Admin::OrderArchivesController < IslayShop::Admin::ApplicationController
  header 'Orders - Archive'
  nav_scope :orders

  def index
    @orders = OrderSummary.summary.archived.page(params[:page]).sorted(params[:sort])
  end
end
