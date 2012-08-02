Islay::Engine.extensions.register do |e|
  e.namespace :islay_shop

  e.admin_styles true
  e.admin_scripts false

  # Navigation
  e.nav_entry('Products', :catalogue, :class => 'icon-archive')
  e.nav_entry('Orders', :orders, :class => 'icon-basket')
  e.nav_entry('Promotions', :promotions, :class => 'icon-star')
end
