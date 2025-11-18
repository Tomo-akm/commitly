Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    omniauth_callbacks: "users/omniauth_callbacks"
  }, skip: [ :registrations ]

  # 新規登録のみ有効化（編集・削除機能は提供しない）
  devise_scope :user do
    post "users", to: "users/registrations#create", as: :user_registration
    get "users/sign_up", to: "users/registrations#new", as: :new_user_registration
  end
  resources :users, only: [] do
    resources :follows, only: [ :create, :destroy ]
  end
  resources :posts do
    resources :likes, only: [ :create, :destroy ]
  end
  resources :tags, only: [ :index, :show ]
  get "home/index"
  get "profile", to: "profiles#show"
  get "profile/likes", to: "profiles#likes", as: "profile_likes"
  get "profile/edit", to: "profiles#edit", as: "edit_profile"
  patch "profile", to: "profiles#update"
  get "users/:id/profile", to: "profiles#show", as: "user_profile"
  get "users/:id/profile/likes", to: "profiles#likes", as: "user_profile_likes"
  get "users/:id/following", to: "profiles#following", as: "following_user"
  get "users/:id/followers", to: "profiles#followers", as: "followers_user"


  # API endpoints for heatmap data
  namespace :api do
    namespace :v1 do
      resources :users do
        get :posts_activity, on: :member
      end
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "posts#index"
end
