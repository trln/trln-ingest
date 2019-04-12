json.extract! transaction, :id, :owner, :status, :files, :created_at, :updated_at
json.user do
  user = transaction.user
  json.id user.id
  json.email user.email
end
json.url transaction_url(transaction, format: :json)
