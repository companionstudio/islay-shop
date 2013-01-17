Islay::Engine.extensions.register do |e|
  e.namespace :islay_shop

  e.admin_styles true
  e.admin_scripts true

  # Navigation
  e.nav_entry('Products', :catalogue)
  e.nav_entry('Orders', :orders)
  e.nav_entry('Promotions', :promotions)

  e.reports('Shop', :shop_reports, :class => 'basket')

  e.dashboard(:primary, :top, :order_overview)
  e.dashboard(:secondary, :top, :stock_alerts)
end
