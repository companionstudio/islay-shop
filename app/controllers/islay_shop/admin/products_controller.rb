module IslayShop
  module Admin
    class ProductsController < ApplicationController
      resourceful :product
      header('Products')

      def show
        @product = Product.find(params[:id])
        dependencies
        render :edit
      end

      private

      def dependencies
        @categories = ProductCategory.all
        @ranges = ProductRange.all
      end
    end
  end
end
