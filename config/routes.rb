require 'sidekiq/web'
Rails.application.routes.draw do
  devise_for :users

  scope '/trln' do
    resources :users
    post '/users/:id/new_token', to: 'users#new_token!'
  end

  resources :transactions
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'transactions#index'

  get '/transaction/:id' => 'transactions#show'
  delete '/transaction/:id' => 'transactions#destroy'

  post '/index/:id', to: 'transactions#start_index', as: 'reindex'
  post '/ingest/:owner', to: 'transactions#ingest_json', constraints: { content_type: 'application/json' }
  post '/ingest/:owner', to: 'transactions#ingest_zip', constraints: { content_type: 'application/zip' }

  get   '/ingest/:owner', to: 'transactions#ingest_form', as: 'ingest_form'
  post  '/ingest/:owner', contraints: { content_type: :multipart_form }, to: 'transactions#upload'

  get   '/record', to: 'documents#index'
  get   '/record/search', to: 'documents#search'
  get   '/record/:id' => 'documents#show', :defaults => { format: 'html'}, as: 'show_document'

  authenticate :user, ->(u) { u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end
end
