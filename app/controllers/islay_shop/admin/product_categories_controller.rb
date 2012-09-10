module IslayShop
  module Admin
    class ProductCategoriesController < IslayShop::Admin::ApplicationController
      helper CatalogueHelper

      resourceful :product_category
      header 'Shop'
      nav 'islay_shop/admin/shop/nav'

      def index
        @product_categories = case params[:filter]
        when 'published'    then ProductCategory.where(:product_category_id => nil, :published => true)
        when 'unpublished'  then ProductCategory.where(:product_category_id => nil, :published => false)
        else ProductCategory.where(:product_category_id => nil)
        end.order('position')
      end

      def show
        super
        if @product_category.products?
          @products = @product_category.products.summary.filtered(params[:filter]).sorted(params[:sort])
        elsif @product_category.children?
          @product_categories = @product_category.children
        end
      end

      private

      def dependencies
        @assets = ImageAsset.order('name')
        @product_categories = category_tree([], ProductCategory.no_products.top_level.order('position'))
      end

      def category_tree(acc, categories, prefix = '')
        categories.each do |c|
          acc << [(prefix + c.name).html_safe, c.id]
          category_tree(acc, c.children, prefix + '&nbsp;&nbsp;') if c.children?
        end

        acc
      end
    end
  end
end
