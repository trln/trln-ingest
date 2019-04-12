json.links do
  next_page = path_to_next_page(@transactions, format: :json)
  prev_page = path_to_prev_page(@transactions, format: :json)
  json.next(next_page) if next_page
  json.prev(prev_page) if prev_page
end

json.transactions do
  json.array! @transactions, partial: 'transactions/transaction', as: :transaction
end
