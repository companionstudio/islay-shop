Islay::Engine.extensions.register do |e|
  e.namespace :islay_shop

  e.admin_styles true
  e.admin_scripts true

  e.configuration('Shop', :islay_shop) do |c|
    binding.pry
    c.string  :notification_email
    c.string  :shop_email
  end

  e.reports('Shop', :shop_reports, :class => 'basket')

  e.dashboard(:primary, :top, :order_overview)
  e.dashboard(:secondary, :top, :stock_alerts)

  e.add_item_entry('Product', :product, 'gift')
  e.add_item_entry('Product Category', :product_category, 'folder-close')
  e.add_item_entry('Product Range', :product_range, 'folder-close')
  e.add_item_entry('Manufacturer', :manufacturer, 'building')
  e.add_item_entry('Promotion', :promotion, 'bullhorn')

  e.nav_section(:catalogue) do |s|
    s.root('Catalogue', :catalogue, 'gift')
    s.sub_nav('Categories', :product_categories)
    s.sub_nav('Products', :products)
    s.sub_nav('Ranges', :product_ranges)
    s.sub_nav('Manufacturers', :manufacturers)
    s.sub_nav('Stock Levels', :stock_levels)
  end

  e.nav_section(:orders) do |s|
    s.root('Shop', :orders, 'shopping-cart')
    s.sub_nav('Latest orders', :orders, :root => true)
    s.sub_nav('Completed orders', :order_archives)
    s.sub_nav('Processing', :order_processes)
    s.sub_nav('Promotions', :promotions)
  end

  e.nav_section(:reports) do |s|
    s.sub_nav('Shop', :shop_reports)
  end
end
