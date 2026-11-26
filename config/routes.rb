Rails.application.routes.draw do
  root "dashboard#show"

  resources :entities, only: %i[index show]
  resources :contracts, only: %i[index show]
  resources :contractors, only: :show
  get "metodologia", to: "pages#methodology", as: :methodology

  resource :session, only: %i[new create destroy]
  resources :passwords, param: :token, only: %i[new create edit update]

  namespace :admin do
    root "contracts#index"
    resources :contracts, except: :show
    resources :entities, except: %i[show destroy]
    resources :contractors, except: %i[show destroy]
    resource :import, only: %i[new create]
  end

  namespace :api do
    namespace :v1, defaults: { format: :json } do
      resources :entities, only: %i[index show]
      resources :contracts, only: %i[index show]
      resources :red_flags, only: :index
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
