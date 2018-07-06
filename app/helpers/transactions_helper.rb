module TransactionsHelper

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
end
