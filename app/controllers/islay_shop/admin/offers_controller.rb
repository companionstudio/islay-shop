module IslayShop
  module Admin
    class OffersController < IslayShop::Admin::ApplicationController
      helper CatalogueHelper

      resourceful :offer
      header 'Offers'
      nav_scope :shop

      def index
        @offers = Offer.page(params[:page]).filtered(params[:filter]).sorted(params[:sort])
      end

      def show
        redirect_to edit_admin_offer_path(id: params[:id])
      end

      private

      def dependencies
        prepare_for_editing if editing? or creating?
      end

      def prepare_for_editing
        @offer.offer_items.build
        @skus = Sku.published.summarize_product.order("product_name ASC").map do |e|
          ["#{e.product_name} - #{e.short_desc}", e.id]
        end
      end
    end
  end
end
