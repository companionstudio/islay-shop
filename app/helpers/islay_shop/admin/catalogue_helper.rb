module IslayShop::Admin::CatalogueHelper
  #Return a list suitable for breadcrumbs, pointing to a category, product or sku
  def ancestor_category_links(source)
    case source.class.name
    when 'ProductCategory'
      source.parent_categories.each do |c|
        sub_header(c.name, admin_product_category_url(c))
      end
      
    when 'Product'
      source.parent_categories.each do |c|
        sub_header(c.name, admin_product_category_url(c))
      end

    when 'Sku'
      source.product.parent_categories.each do |c|
        sub_header(c.name, admin_product_category_url(c))
      end
    end
  end

  def sku_sale_status(sku)
    content_tag(:span, sku.status.humanize, :class => "indicator status #{sku.status}")
  end
end