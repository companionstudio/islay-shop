module IslayShop
  module Admin
    class ProductCategoriesController < IslayShop::Admin::ApplicationController
      helper CatalogueHelper
      
      resourceful :product_category
      header 'Shop'
      nav 'islay_shop/admin/shop/nav'

      def index
        @product_categories = case params[:filter]
        when 'published'    then ProductCategory.where(:product_category_id => nil, :published => true)
        when 'unpublished'  then ProductCategory.where(:product_category_id => nil, :published => false)
        else ProductCategory.where(:product_category_id => nil)
        end.order('position')
      end

      def show
        super
        @products = @product_category.products.summary.filtered(params[:filter]).sorted(params[:sort])
      end

      private

      def dependencies
        @assets = ImageAsset.order('name')
        @product_categories = if params[:id]
          ProductCategory.where("product_category_id IS NULL AND slug != ?", params[:id]).order('position')
        else
          ProductCategory.where("product_category_id IS NULL").order('position')
        end
      end
    end
  end
end
