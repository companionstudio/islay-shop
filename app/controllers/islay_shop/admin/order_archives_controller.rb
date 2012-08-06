class IslayShop::Admin::OrderArchivesController < IslayShop::Admin::ApplicationController
  header 'Shop - Order Archive'
  nav 'islay_shop/admin/orders/nav'

  def index
    @orders = OrderSummary.summary.archived.page(params[:page]).sorted(params[:sort])
  end
end
