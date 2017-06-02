module IslayShop
  module Admin
    class ProductsController < IslayShop::Admin::ApplicationController
      helper CatalogueHelper

      resourceful :product
      header 'Catalogue - Products'
      nav_scope :catalogue

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
        @categories     = ProductCategory.tree.mark_disabled
        @ranges         = ProductRange.all
        @manufacturers  = Manufacturer.order('name')
        @assets         = Asset.order('name')
      end

      def permitted_params
        params.permit(:product => [
          :name, :description, :product_category_id, :product_range_id, :manufacturer_id,
          :published, :status, :skus_attributes, :asset_ids, :position
        ])
      end
    end
  end
end
