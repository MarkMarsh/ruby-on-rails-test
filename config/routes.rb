require 'sidekiq/web'

Rails.application.routes.draw do
  root to: 'file_stats#index'

  if Rails.env.development?
    mount Sidekiq::Web => '/sidekiq'
  end
  
  resources :file_stats

  put '/file_stats/:id/pause', to: "file_stats#pause", as: 'pause_file_stat'
  put '/file_stats/:id/unpause', to: "file_stats#unpause", as: 'unpause_file_stat'
  put '/file_stats/:id/cancel', to: "file_stats#cancel", as: 'cancel_file_stat'
  
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
