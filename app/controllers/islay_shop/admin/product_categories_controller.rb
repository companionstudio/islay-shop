module IslayShop
  module Admin
    class ProductCategoriesController < IslayShop::Admin::ApplicationController
      resourceful :product_category
      header 'Shop'
      nav 'islay_shop/admin/shop/nav'

      def index
        @product_categories = case params[:filter]
        when 'published'    then ProductCategory.where(:product_category_id => nil, :published => true)
        when 'unpublished'  then ProductCategory.where(:product_category_id => nil, :published => false)
        else ProductCategory.where(:product_category_id => nil)
        end
      end

      private

      def dependencies
        @assets = ImageAsset.order('name')
        @product_categories = if params[:id]
          ProductCategory.where("product_category_id IS NULL AND id != ?", params[:id]).order('position')
        else
          ProductCategory.where("product_category_id IS NULL").order('position')
        end
      end
    end
  end
end
