class IslayShop::Admin::ProductRangesController < IslayShop::Admin::ApplicationController
  
  resourceful :product_range
  header 'Catalogue - Product Ranges'
  nav_scope :catalogue

end
