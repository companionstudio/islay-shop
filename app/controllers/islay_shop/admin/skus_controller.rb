class IslayShop::Admin::SkusController < IslayShop::Admin::ApplicationController
  helper IslayShop::Admin::CatalogueHelper
  resourceful :sku, :parent => :product
  header 'Shop'
  nav_scope :catalogue

  def new
    @sku = Sku.new({:product_id => @product.id})
    @sku.default_single_price_point
    dependencies
    render :layout => !request.xhr?
  end

  private

  def dependencies
    @assets = Asset.order('name')
    if integrate_blog?
      @blog_entries = BlogEntry.order('published_at DESC')
    end
  end

  def redirect_for(record)
    path(:edit, @product, @sku)
  end

  def destroy_redirect_for(record)
    path(@product)
  end
end
