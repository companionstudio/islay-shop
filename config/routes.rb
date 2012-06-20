Rails.application.routes.draw do
  scope :module => 'islay_shop' do
    namespace :admin do
      scope :path => 'catalogue' do
        get '/' => 'shop#index', :as => 'catalogue'

        resources :products, :path => 'categories/products' do
          get :delete, :on => :member
          resources :product_assets, :path => 'assets'
          resources :sku do
            resources :sku_assets, :path => 'assets'
            get :delete, :on => :member
          end
        end

        resources :product_categories, :path => 'categories' do
          get :delete, :on => :member
        end

        resources :product_ranges, :path => 'ranges' do
          get :delete, :on => :member
        end

      end

      scope :path => 'orders', :controller => 'orders' do
        get '/',    :action => 'index', :as => 'orders'
        get '/:id', :action => 'show', :as => 'order'
      end

      resources :promotions
    end # namespace

    namespace :public, :path => '' do
      # TODO: Make these paths configurable
      scope :path => 'catalogue', :controller => 'catalogue' do
        get '/', :action => 'index', :as => 'catalogue'
      end

      scope :path => 'basket', :controller => 'basket' do
        get     '/',                :action => 'contents',  :as => 'order_basket'
        post    '/add',             :action => 'add',       :as => 'order_basket_add'
        post    '/remove/:sku_id',  :action => 'remove',    :as => 'order_basket_remove'
        post    '/update',          :action => 'remove',    :as => 'order_basket_update'
        delete  '/clear',           :action => 'clear',     :as => 'order_basket_clear'
      end

      scope :path => 'checkout', :controller => 'checkout' do
        get '/',        :action => 'contact',   :as => 'order_checkout'
        get '/payment', :action => 'payment',   :as => 'order_checkout_payment'
      end
    end
  end # scope
end # draw
