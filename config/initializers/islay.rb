Islay::Engine.extensions.register do |e|
  e.namespace :islay_shop

  e.admin_styles true
  e.admin_scripts true

  e.navigation do |n|
    n.section('Catalogue', :catalogue, 'gift')
    n.section('Orders', :orders, 'shopping-cart')
  end

  e.reports('Shop', :shop_reports, :class => 'basket')

  e.dashboard(:primary, :top, :order_overview)
  e.dashboard(:secondary, :top, :stock_alerts)
end
