Rails.application.routes.draw do
  islay_admin 'islay_shop' do
    range = "(/month-:year-:month)(/range/:from/:to)"

    scope :path => 'reports/shop', :controller => 'reports' do
      get range, :action => :index,    :as => 'shop_reports'

      get "totals",                                 :action => :totals,   :as => 'order_totals'
      get "orders#{range}",                         :action => :orders,   :as => 'order_reports'
      get 'products',                               :action => :products, :as => 'product_reports'
      get "products/:id#{range}",                   :action => :product,  :as => 'product_report'
      get "products/:product_id/skus/:id#{range}",  :action => :sku,      :as => 'sku_report'
    end

    scope :path => 'catalogue' do
      get '/' => redirect('/admin/catalogue/categories'), :as => 'catalogue'

      resources :products do
        collection do
          get '(/filter-:filter)(/sort-:sort)(/page-:page)', :action => :index, :as => 'filter_and_sort'
          put 'position', :action => :update_position, :as => 'position'
        end

        get :delete, :on => :member

        resources :product_assets,  :path => 'assets'
        resources :stock_logs,      :only => 'index'
        resources :sku_price_logs,  :only => 'index', :path => 'price_logs'

        resources :skus do
          put 'position', :action => :update_position, :as => 'position', :on => :collection
          get :delete, :on => :member
          resources :sku_assets, :path => 'assets'
        end
      end

      resources :product_categories, :path => 'categories' do
        collection do
          get '(/filter-:filter)',  :action => :index,           :as => 'filter_and_sort'
          put 'position',           :action => :update_position, :as => 'position'
        end

        member do
          get :delete
          get 'products(/filter-:filter)(/sort-:sort)', :action => :show, :as => 'filter_and_sort'
        end
      end

      resources :product_ranges, :path => 'ranges' do
        get :delete, :on => :member
      end

      resources :stock_levels, :path => 'stock', :only => 'index' do
        collection do
          get '(/filter-:filter)(/sort-:sort)', :action => 'index', :as => 'filter_and_sort'
          put '', :action => 'update'
        end
      end
    end

    scope :path => 'orders' do
      resources :order_processes, :path => 'processing', :only => 'index' do
        collection do
          %w(billing packing shipping recent).each do |f|
            get "#{f}/(sort-:sort)(/page-:page)", :action => f, :as => f, :defaults => {:filter => f}
          end

          # This is just a dummy route to help us generate the URLs for the
          # routes above. Basically, it makes the filter and sorting helpers
          # just work.
          get '(/:filter)(/sort-:sort)(/page-:page)',   :action => 'index', :as => 'filter_and_sort'

          put 'ship/all',     :action => 'ship_all', :as => 'ship_all'
          put 'packing/all',  :action => 'pack_all',  :as => 'pack_all'
        end

        member do
          get 'billing',  :action => 'review_billing', :as => 'bill'
          put 'billing',  :action => 'bill'

          put 'packing',  :action => 'pack', :as => 'pack'
          put 'shipping', :action => 'ship', :as => 'ship'

          get 'cancel',   :action => 'review_cancellation', :as => 'cancel'
          put 'cancel',   :action => 'cancel'

          put 'update',   :action => 'update', :as => 'update'
        end
      end

      resources :order_archives, :path => 'archives', :only => 'index' do
        get '(/filter-:filter)(/sort-:sort)(/page-:page)',  :action => 'index', :as => 'filter_and_sort', :on => :collection
      end
    end

    resources :orders, :only => %w(index show edit update) do
      get '(/sort-:sort)(/page-:page)', :action => 'index', :on => :collection, :as => 'filter_and_sort'

      member do
        get 'payment',  :action => 'edit_payment', :as => 'payment'
        put 'payment',  :action => 'update_payment'
        get 'delete'
      end
    end

    resources :order_summaries, :controller => 'orders', :path => 'orders', :only => 'show'

    resources :promotions

    resources :manufacturers do
      get :delete, :on => :member
    end
  end # admin

  unless Settings.defined?(:shop, :disabled) and Settings.for(:shop, :disabled)
    islay_public 'islay_shop' do
      namespace :basket, :path => 'order/basket', :as => 'order_basket' do
        post    '/add',             :action => 'add',             :as => 'add'
      end
    end

    islay_secure_public 'islay_shop' do
      namespace :basket, :path => 'order/basket', :as => 'order_basket' do
        get     '/',                :action => 'contents',        :as => ''
        post    '/remove/:sku_id',  :action => 'remove',          :as => 'remove'
        post    '/',                :action => 'update',          :as => 'update'
        delete  '/',                :action => 'destroy',         :as => 'destroy'
        delete  '/alerts',          :action => 'destroy_alerts',  :as => 'destroy_alerts'
      end
      namespace :checkout, :path => '/order/checkout', :as => 'order_checkout' do
        get   '/',                        :action => 'details',         :as => ''
        post  '/',                        :action => 'update'
        get   '/payment',                 :action => 'payment',         :as => 'payment'
        get   '/payment/process',         :action => 'payment_process', :as => 'payment_process'
        get   '/thank-you/(:reference)',  :action => 'thank_you',      :as => 'thank_you'
      end
    end # scope
  end # unless Settings
end # draw

