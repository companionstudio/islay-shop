module IslayShop::Admin::CatalogueHelper
  def sku_sale_status(sku)
    content_tag(:span, sku.status.humanize, :class => "indicator status #{sku.status}")
  end
end