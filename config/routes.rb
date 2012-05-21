Rails.application.routes.draw do
  scope :module => 'islay_shop' do
    namespace :admin do
      get '/shop' => 'shop#index', :as => 'shop'
    end
  end
end
