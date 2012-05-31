module IslayShop
  module Admin
    class ProductCategoriesController < ApplicationController
      resourceful :product_category
      header('Shop')

      def index
        @product_categories = ProductCategory.where(:product_category_id => nil)
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
