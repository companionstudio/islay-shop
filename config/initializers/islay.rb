Islay::Engine.extensions.register do |e|
  e.namespace :islay_shop

  e.admin_styles true
  e.admin_scripts false

  # Navigation
  e.nav_entry('Products', :catalogue)
  e.nav_entry('Orders', :orders)
  e.nav_entry('Promotions', :promotions)
end
