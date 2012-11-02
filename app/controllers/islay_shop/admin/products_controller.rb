module IslayShop
  module Admin
    class ProductsController < IslayShop::Admin::ApplicationController
      helper CatalogueHelper

      resourceful :product
      header 'Shop - Products'
      nav 'islay_shop/admin/shop/nav'

      def index
        @products = Product.summary.page(params[:page]).filtered(params[:filter]).sorted(params[:sort])
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
        @categories = ProductCategory.tree.mark_disabled
        @ranges = ProductRange.all
        @assets = Asset.order('name')
      end
    end
  end
end
