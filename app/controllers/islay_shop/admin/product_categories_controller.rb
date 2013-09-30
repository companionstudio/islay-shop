module IslayShop
  module Admin
    class ProductCategoriesController < IslayShop::Admin::ApplicationController
      helper CatalogueHelper

      resourceful :product_category
      header 'Catalogue - Categories'
      nav_scope :catalogue

      def index
        @product_categories = case params[:filter]
        when 'published'    then ProductCategory.summary.top_level.published
        when 'unpublished'  then ProductCategory.summary.top_level.published(false)
        else ProductCategory.summary.top_level
        end.order('position')
      end

      def show
        super
        if @product_category.products?
          @products = @product_category.products.summary.filtered(params[:filter]).sorted(params[:sort])
        elsif @product_category.children?
          @product_categories = @product_category.children.summary
        end
      end

      private

      def dependencies
        @assets = ImageAsset.order('name')
        @product_categories = ProductCategory.tree.potential_parents(@product_category.id)
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
