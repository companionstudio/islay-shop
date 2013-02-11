class ActionDispatch::Routing::Mapper
  # Installs the default public routes and controllers for the webshop. This is 
  # done so that these particular routes are optional. In some applications, 
  # the public routes need to be customised e.g. 'wines' instead of 'products'.
  #
  # @param String prefix
  #
  # @return nil
  def public_shop_catalogue(prefix = 'catalogue')
    islay_public 'islay_shop' do
      scope :path => prefix, :controller => 'catalogue' do
        get '', :action => 'index', :as => 'catalogue'
        get 'categories'
        get 'category/:id', :action => 'category', :as => 'product_category'
        get 'products'
        get 'product/:id', :action => 'product', :as => :product
      end
    end
  end
end

