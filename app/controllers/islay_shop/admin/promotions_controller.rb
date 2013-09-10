module IslayShop
  module Admin
    class PromotionsController < IslayShop::Admin::ApplicationController
      resourceful :promotion
      header 'Promotions'
      nav 'islay_shop/admin/orders/nav'

      def show
        @promotion = Promotion.find(params[:id])
      end

      private

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
