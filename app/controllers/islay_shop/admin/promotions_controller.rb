module IslayShop
  module Admin
    class PromotionsController < ApplicationController
      resourceful :promotion
      header 'Promotions'

      def show
        @promotion = Promotion.find(params[:id])
        @promotion.prefill
        render :edit
      end
    end
  end
end
