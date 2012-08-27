module IslayShop
  module Admin
    class ApplicationController < Islay::Admin::ApplicationController
      helper_method :integrate_blog?

      # Checks the Islay engine configuration to see if the shop should integrate
      # with the blog i.e. entries can be linked to SKUs.
      #
      # @return Boolean
      def integrate_blog?
        !!Islay::Engine.config.integrate_shop_and_blog
      end
    end
  end
end
