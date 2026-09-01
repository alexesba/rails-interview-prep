Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :users, only: [] do
    collection do
      get :search
    end
  end

  resources :projects do
    resources :tasks, only: %i[index create] do
      member do
        patch :assign
      end
    end
  end
end
