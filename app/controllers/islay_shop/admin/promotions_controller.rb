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

      private

      def invalid_record
        @promotion.prefill
      end

      def find_record
        if params[:action] == 'show'
          Promotion.find(params[:id]).tap(&:prefill)
        else
          Promotion.find(params[:id])
        end
      end

      def new_record
        if params[:action] == 'new'
          Promotion.new.tap(&:prefill)
        else
          Promotion.new
        end
      end
    end
  end
end
