Rails.application.routes.draw do
  resources :leads, only: %i[index show new create destroy] do
    member do
      post :re_score
    end
  end
  resource :setting, only: :update
  root "leads#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
