require 'sidekiq/web'

Rails.application.routes.draw do
  root to: 'file_stats#index'

  #if Rails.env.development?
    mount Sidekiq::Web => '/sidekiq'
  #end
  
  resources :file_stats
  
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
