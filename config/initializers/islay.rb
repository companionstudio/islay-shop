Islay::Engine.extensions.register do |e|
  e.namespace :islay_shop

  e.admin_styles true
  e.admin_scripts false

  # Navigation
  e.nav_entry('Products', :product_categories)
  e.nav_entry('Orders', :orders)
  e.nav_entry('Promotions', :promotions)

  e.dashboard(:primary, :top, :order_overview)
  e.dashboard(:secondary, :top, :stock_alerts)
end
