module IslayShop
  class Engine < ::Rails::Engine
    config.autoload_paths << File.expand_path("../../app/queries", __FILE__)
  end
end
