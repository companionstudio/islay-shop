# This is terrible. By rights this should be IslayShop::ApplicationCell,
# but the AutoLoader won't deal with it (cross-loading between engines, maybe?)
class IslayShopCell < Islay::ApplicationCell
  view_paths << "#{IslayShop::Engine.root}/app/cells"
end
