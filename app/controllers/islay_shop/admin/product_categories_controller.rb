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
          ProductCategory.where("id != ?", params[:id]).order('position')
        else
          ProductCategory.order('position')
        end
      end
    end
  end
end
