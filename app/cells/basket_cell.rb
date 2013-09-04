class BasketCell < Cell::Rails
  include IslayShop::ControllerExtensions::Public
  
  helper_method :parent_controller

  def short
    render
  end
end
