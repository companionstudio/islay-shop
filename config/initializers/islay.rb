Islay::Engine.extensions.register do |e|
  e.namespace :islay_shop

  # Navigation
  e.nav_entry('Products', :catalogue, :class => 'icon-archive')
  e.nav_entry('Orders', :orders, :class => 'icon-basket')
end
