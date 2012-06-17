module IslayShop
  module Admin
    class ProductsController < ApplicationController
      resourceful :product
      header('Products')

      def show
        dependencies
        @product = find_record
        render :edit
      end

      private

      def invalid_record
        @product.skus.build(:template => true)
      end

      def new_record
        if params[:action] == 'new'
          Product.new.tap {|p| p.skus.build(:template => true)}
        else
          Product.new
        end
      end

      def find_record
        if params[:action] == 'show'
          Product.find(params[:id]).tap {|p| p.skus.build(:template => true)}
        else
          Product.find(params[:id])
        end
      end

      def dependencies
        @categories = ProductCategory.all
        @ranges = ProductRange.all
      end
    end
  end
end