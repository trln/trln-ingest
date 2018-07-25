module TransactionsHelper
  STATUS_LABELS = {
    'Ingesting' => {
      label_class: 'warning',
      text: 'Loading records into database',
    },
    'Indexing' => {
      label_class: 'info',
      text: 'Transforming and loading records into Solr',
    },
    'Archived' => {
      label_class: 'secondary',
      text:  'complete, files are compressed and ready for cold storage'
    },
    'Complete' => {
      label_class: 'primary',
      text: 'All (valid) documents have been stored and loaded into Solr'
    }
  }.freeze

  def filename_for_download
    name = File.basename(params[:filename])
    name += '.json' if request.format.symbol == :json
    name
  end

  def path_for_download(name)
    if @transaction.status == 'Archived'
      @transaction.files[0]
    else
      File.join(File.join(@transaction.stash_directory, name))
    end
  end

  def mime_type_from_filename(name)
    return nil unless name
    ext = File.extname(name)[1..-1]
    Mime::Type.lookup_by_extension(ext)    
  end

  def sidekiq_job_status(id)
    tx_workers = %w[IndexingWorker TransactionWorker]
    Sidekiq::Workers.new.each do |_pid, _thread, wk|
      payload = wk['payload']
      if payload['args'] == [id] && tx_workers.include?(payload['class'])
        return 'Running'
      end
    end

    Sidekiq::RetrySet.new.select do |job|
      next unless tx_workers.include?(job.klass.to_s)
      return 'Retrying' if job.args == [id]
    end
    'Done'
  end

  def status_label_class(txn)
    STATUS_LABELS.fetch(txn.status, label_class: 'danger')[:label_class]
  end

  def status_description(txn)
    STATUS_LABELS.fetch(txn.status, text: 'Unknown')[:text]
  end
end
