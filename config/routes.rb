Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#index"

  resources :companies do
    resources :contacts, only: [:new, :create]
  end

  resources :contacts, only: [:show, :edit, :update]

  resources :drafts, only: [:index, :show, :edit, :update] do
    member do
      post :approve
      post :send_email
    end
  end

  resources :followups, only: [:index] do
    member do
      post :skip
    end
  end

  resources :meetings

  resources :task_monitor, only: [:index] do
    member do
      post :retry_task
    end
  end

  get "settings", to: "settings#index"
  patch "settings/followup_defaults", to: "settings#update_followup_defaults"

  # Gmail OAuth
  get "auth/gmail", to: "gmail_auth#redirect"
  get "auth/gmail/callback", to: "gmail_auth#callback"

  # API (for external Claude agent)
  namespace :api do
    get "tasks/next", to: "tasks#next_task"
    post "tasks/:id/claim", to: "tasks#claim"
    post "tasks/:id/start", to: "tasks#start"
    post "tasks/:id/complete", to: "tasks#complete"
    post "tasks/:id/fail", to: "tasks#fail_task"

    post "companies", to: "companies#create"
    post "companies/bulk", to: "companies#bulk_create"
    post "contacts/bulk", to: "contacts#bulk_create"
    post "drafts/bulk", to: "drafts#bulk_create"

    get "apollo/available", to: "apollo_accounts#available"
    post "apollo/usage", to: "apollo_accounts#update_usage"
  end
end
