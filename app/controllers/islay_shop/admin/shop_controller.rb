module IslayShop
  module Admin
    class ShopController < IslayShop::Admin::ApplicationController
      header('Shop')

      def index
        @products = Product.all
      end
    end
  end
end
