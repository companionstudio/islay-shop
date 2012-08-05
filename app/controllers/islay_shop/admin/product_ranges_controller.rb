class IslayShop::Admin::ProductRangesController < IslayShop::Admin::ApplicationController
  resourceful :product_range
  header 'Shop - Product Ranges'
  nav 'islay_shop/admin/shop/nav'

end
