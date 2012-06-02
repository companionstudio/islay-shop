module IslayShop
  module Admin
    class ProductsController < ApplicationController
      resourceful :product
      header('Products')

      before_filter :add_templates, :except => [:index, :delete, :destroy]

      def show
        dependencies
        render :edit
      end

      private

      def add_templates
        @product ||= Product.find(params[:id])
        @product.skus.build(:template => true)
      end

      def dependencies
        @categories = ProductCategory.all
        @ranges = ProductRange.all
      end
    end
  end
end
