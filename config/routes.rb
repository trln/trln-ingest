require 'sidekiq/web'
Rails.application.routes.draw do
  resources :transactions
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
    root to: "transactions#index"

  post '/ingest/:owner', to: 'transactions#ingest_json', constraints: { content_type: 'application/json' }
  post '/ingest/:owner', to: 'transactions#ingest_zip', constraints: { content_type: 'application/zip' }

  get   '/ingest/:owner', to: 'transactions#ingest_form' , as: 'ingest_form'
  post  '/ingest/:owner', contraints: { content_type: :multipart_form }, to: 'transactions#upload'

  get   '/record', to: 'documents#index'
  get   '/record/:id' => 'documents#show', :defaults => { :format => 'html'}, as: 'show_document'

  mount Sidekiq::Web => '/sidekiq'

end
