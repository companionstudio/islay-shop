module IslayShop
  module Admin
    class PromotionsController < IslayShop::Admin::ApplicationController
      resourceful :promotion
      header 'Orders - Promotions'
      nav_scope :orders

      def index
        @promotions = Promotion.summary.page(params[:page]).filtered(params[:filter]).sorted(params[:sort])
      end

      def show
        @promotion = Promotion.find(params[:id])
      end

      private

      def dependencies
        @skus = Sku.published.summarize_product.map do |e| 
          ["#{e.product_name} - #{e.short_desc}", e.id]
        end

        @shipping_discount_modes = [
          ["Set Total", "set"], 
          ["Fixed", "fixed"], 
          ["Percentage", "percentage"]
        ]

        @categories = ProductCategory.tree
        @products = Product.published
      end

      def invalid_record
        @promotion.prefill
      end

      def find_record
        if params[:action] == 'edit'
          Promotion.find(params[:id]).tap(&:prefill)
        else
          Promotion.find(params[:id])
        end
      end

      def new_record
        Promotion.new.tap(&:prefill)
      end
    end
  end
end
