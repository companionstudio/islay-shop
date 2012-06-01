Islay::Engine.extensions.register do |e|
  e.namespace :islay_shop

  # Navigation
  e.nav_entry('Products', :catalogue)
  e.nav_entry('Orders', :orders)
end
