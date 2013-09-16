Rails.application.routes.draw do

  get '/beacon.gif' => "beacon#index"
  get "/404", :to => "errors#page_not_found"
  get "/500", :to => "errors#went_wrong"

  post 'notifications/:classification' => 'payment_notifications#create'
  post 'notifications/paypal/:classification' => 'payment_notifications#create_from_paypal'

  scope "/:locale", :locale => /(..){1}/ do
    root :to => "home#index", :as => 'home'
    resource  :activity, :only => [:show]
    resources :members, :only => [:index, :create]
    resources :actions, :only => [:show] do
      member do
        post :take_action
        post :setup_paypal_donation
        get  :return_from_paypal
        put  :complete_paypal_donation
        post :donate_with_credit_card
        get :preview
      end
      get :member_fields
      get :member_info
    end
    get 'preview' => 'home#preview'
    get ":content_page" => "content_pages#show", :as => :content_page
    get ":content_page/preview" => "content_pages#preview", :as => :content_page_preview
  end

  resources :shares, :only => [:create]

  root :to => "home#index"

  namespace :admin, :path => "awesomeness" do
    get "dashboard(.:format)" => "health_dashboard#index"
  end

  get '*path' => "home#redirect"
end
