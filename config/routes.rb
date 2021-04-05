# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  require 'sidekiq/web'
  require 'sidekiq-scheduler/web'

  post 'webhook/:store/created_orders', to: 'webhook#created_orders'
  get 'webhook/health_test', to: 'webhook#health_test'

  # Logs
  get '/errors(/:store_sku)', to: 'dashboard#errors', as: :dashboard_errors
  get '/logs', to: 'logs#index'
  get '/logs/errors', to: 'logs#errors'
  get '/logs/changes', to: 'logs#changes'

  # Dashboard
  root to: 'dashboard#index'
  get '/store/:store_sku/:resource(/:product_sku)', to: 'dashboard#show', as: :dashboard_show
  get 'active_sync', to: 'dashboard#active_synchronizer'

  mount Sidekiq::Web => '/sidekiq'
end
