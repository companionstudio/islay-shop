class IslayShop::Admin::SkusController < IslayShop::Admin::ApplicationController
  helper IslayShop::Admin::CatalogueHelper
  resourceful :sku, :parent => :product
  header 'Shop'
  nav 'islay_shop/admin/shop/nav'

  private

  def dependencies
    @sku.price_points.build(:current => true, :valid_from => Time.now, :price => '0')
    @assets = Asset.order('name')
    if integrate_blog?
      @blog_entries = BlogEntry.order('published_at DESC')
    end
  end

  def redirect_for(record)
    path(@product)
  end

  def destroy_redirect_for(record)
    path(@product)
  end
end
