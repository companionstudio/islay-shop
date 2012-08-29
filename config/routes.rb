Rails.application.routes.draw do
  scope :module => 'islay_shop' do
    namespace :admin do
      scope :path => 'catalogue' do
        get '/' => redirect('/admin/catalogue/categories'), :as => 'catalogue'

        resources :products do
          collection do
            get '(/filter-:filter)(/sort-:sort)(/page-:page)', :action => :index, :as => 'filter_and_sort'
            put 'position', :action => :update_position, :as => 'position'
          end

          get :delete, :on => :member

          resources :product_assets, :path => 'assets'

          resources :skus do
            resources :sku_assets, :path => 'assets'
            get :delete, :on => :member
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
            get 'billing/:id',  :action => 'review_billing', :as => 'bill'
            put 'billing/:id',  :action => 'bill'

            put 'packing/:id',  :action => 'pack', :as => 'pack'
            put 'shipping/:id', :action => 'ship',     :as => 'ship'

            get 'cancel/:id',   :action => 'review_cancellation', :as => 'cancel'
            put 'cancel/:id',   :action => 'cancel'
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
    end # namespace

    namespace :public, :path => '' do
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
