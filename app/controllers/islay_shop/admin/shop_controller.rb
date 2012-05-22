module IslayShop
  module Admin
    class ShopController < ApplicationController
      header('Shop')

      def index
        @products = Product.all
      end
    end
  end
end
