module IslayShop
  module Admin
    class ApplicationController < ActionController::Base
      include Islay::AdminController
    end
  end
end
