Rails.application.routes.draw do
  namespace :admin, :path => "awesomeness" do
    get "dashboard.json" => "health_dashboard#index"
  end
end