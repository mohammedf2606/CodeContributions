Rails.application.routes.draw do
  root 'home#index'
  get 'home/index'
  get '/users/auth/github/callback', to: 'home#callback'
  resources :repos do
    resources :files
  end

end
