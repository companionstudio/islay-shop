Rails.application.routes.draw do
  scope :module => 'islay_shop' do
    namespace :admin do
      scope :path => 'catalogue' do
        get '/' => 'shop#index', :as => 'catalogue'

        resources :products do
          get '(/filter-:filter)(/sort-:sort)', :action => :index, :on => :collection, :as => 'filter_and_sort'

          get :delete, :on => :member

          resources :product_assets, :path => 'assets'

          resources :sku do
            resources :sku_assets, :path => 'assets'
            get :delete, :on => :member
          end
        end

        resources :product_categories, :path => 'categories' do
          get '(/filter-:filter)', :action => :index, :on => :collection, :as => 'filter_and_sort'

          member do
            get :delete
            get '(/filter-:filter)(/sort-:sort)', :action => :show, :as => 'filter_and_sort'
          end
        end

        resources :product_ranges, :path => 'ranges' do
          get :delete, :on => :member
        end

      end

      scope :path => 'orders' do
        scope :path => 'process', :controller => 'order_processing' do
          get '', :action => 'index', :as => 'order_processing'
        end

        get 'archived(/filter-:filter)(/sort-:sort)', :controller => 'order_archive', :action => 'index', :as => 'order_archive'
      end

      resources :orders do
        get '(sort-:sort)', :action => 'index', :on => :collection, :as => 'filter_and_sort'
        get 'delete', :on => :member
      end

      resources :order_summaries, :controller => 'orders', :path => 'orders', :only => 'show'

      resources :promotions
    end # namespace

    namespace :public, :path => '' do
      # TODO: Make these paths configurable
      scope :path => 'catalogue', :controller => 'catalogue' do
        get '/',              :action => 'index',       :as => 'catalogue'
        get '/categories',    :action => 'categories',  :as => 'product_categories'
        get '/category/:id',  :action => 'category',    :as => 'product_category'
        get '/ranges',        :action => 'ranges',      :as => 'product_ranges'
        get '/range/:id',     :action => 'range',       :as => 'product_range'
        get '/products',      :action => 'products',    :as => 'products'
        get '/product/:id',   :action => 'product',     :as => 'product'
      end

      scope :path => 'basket', :controller => 'basket' do
        get     '/',                :action => 'contents',        :as => 'order_basket'
        post    '/add',             :action => 'add',             :as => 'order_basket_add'
        post    '/remove/:sku_id',  :action => 'remove',          :as => 'order_basket_remove'
        post    '/',                :action => 'update',          :as => 'order_basket_update'
        delete  '/',                :action => 'destroy',         :as => 'order_basket_destroy'
        delete  '/alerts',          :action => 'destroy_alerts',  :as => 'order_basket_destroy_alerts'
      end

      scope :path => 'checkout', :controller => 'checkout' do
        get   '/',                :action => 'details',       :as => 'order_checkout'
        post  '/',                :action => 'update'
        get   '/payment',         :action => 'payment',       :as => 'order_checkout_payment'
        get   '/payment/process', :action => 'payment_error', :as => 'order_checkout_payment_process'
        get   '/thank-you',       :action => 'thank_you',     :as => 'order_checkout_thank_you'
      end
    end
  end # scope
end # draw
