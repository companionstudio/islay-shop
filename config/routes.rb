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

      scope :path => 'orders' do
        get '/' => 'orders#index', :as => 'orders'
      end

      resources :promotions
    end # namespace
  end # scope
end # draw
