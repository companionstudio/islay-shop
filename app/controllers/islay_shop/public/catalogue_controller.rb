class IslayShop::Public::CatalogueController < IslayShop::Public::ApplicationController
  def index
    @newest_products  = Product.newest
    @categories       = ProductCategory.published
    @ranges           = ProductRange.published
  end

  def categories
    @categories = ProductCategory.published
  end

  def category
    @category = ProductCategory.find(params[:id])
  end

  def ranges
    @ranges = ProductRange.published
  end

  def range
    @range = ProductRange.find(params[:id])
  end

  def product
    @product = Product.find(params[:id])
  end
end
