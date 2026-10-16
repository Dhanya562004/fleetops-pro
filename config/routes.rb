Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  resource :session, only: %i[new create destroy]
  resources :vehicles do
    collection { get :export }
  end
  resources :lots, only: :index do
    post "moves", to: "moves#create", as: :moves
  end
  resources :maintenance_tickets, only: %i[index show update] do
    resources :ticket_comments, only: :create
    resources :ticket_parts, only: :create do
      member { post :fulfill }
    end
    member do
      post :transition
      get :activity
    end
  end
  get "parts/shortages", to: "parts#shortages", as: :part_shortages
  get "technicians", to: "technicians#index", as: :technicians
  get "analytics", to: "analytics#show", as: :analytics
  root "dashboard#show"
end
