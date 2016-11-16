json.extract! transaction, :id, :owner, :user, :status, :files, :created_at, :updated_at
json.url transaction_url(transaction, format: :json)