module IslayShop
  module Admin
    class PromotionsController < IslayShop::Admin::ApplicationController
      require 'csv'

      resourceful :promotion
      header 'Orders - Promotions'
      nav_scope :orders

      def index
        @promotions = Promotion.summary.page(params[:page]).filtered(params[:filter]).sorted(params[:sort])
      end

      def show
        @promotion = Promotion.find(params[:id])
      end

      def codes
        @promotion = Promotion.find(params[:id])
        if @promotion and @promotion.code_based?
          unless @promotion.codes.empty?
            csv_data = CSV.generate(:headers => :first_row) do |csv|
              csv << ['Code', 'Status']
              @promotion.codes.each {|c| csv << [c.code, c.redeemed_at.blank? ? 'Active' : "Redeemed: #{c.redeemed_at}" ] }
            end
            send_data(csv_data, :type => 'text/csv; charset=utf-8; header=present', :filename => "promotion_codes_for_#{@promotion.name.parameterize}.csv")
          end
        end
      end

      private

      def dependencies
        @skus = Sku.published.summarize_product.order(:product_name).map do |e|
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
