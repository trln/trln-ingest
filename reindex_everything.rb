Transaction.find_by_sql("select t.* FROM transactions t where EXISTS( select 1 from documents d where d.txn_id::integer = t.id )").each do |tx| 
    IndexingWorker.perform_async(tx.id)
end

