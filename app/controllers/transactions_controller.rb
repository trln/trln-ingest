# Controller for managing transactions
class TransactionsController < ApplicationController
  include Spofford::IngestHelper

  protect_from_forgery except: %i[ingest_json ingest_zip]
  acts_as_token_authentication_handler_for User, only: %i[index show ingest_zip ingest_json], fallback: :exception

  before_action :authenticate_user!
  before_action :set_transaction, only: %i[show edit update destroy archive]

  # GET /transactions
  # GET /transactions.json
  def index
    filters = { owner: current_user.primary_institution }
    filters = {} if params[:view] == 'all'
    @transactions = Transaction.where(filters).page(params[:page]).order('created_at DESC')
    @filtered = !filters.empty?
  end

  # GET /transactions/1
  # GET /transactions/1.json
  def show
    @document_ids = Document.where(txn: @transaction).select(:id, :local_id)
    @job_status = helpers.sidekiq_job_status(@transaction.id)
    @zip_entries = Hash[@transaction.files.select { |f| File.exist?(f) && File.extname(f) == '.zip' }
                               .map { |f| [f, helpers.zip_contents(f)] }]
  end

  # GET /transactions/:id/edit
  def edit
    start_worker
  end

  def archive
    @transaction.archive!
  end

  # POST /ingest/:owner ( application/zip )
  def ingest_zip
    if request.body.size.zero?
      logger.info("#{params[:owner]} -- received empty body")
      return render(text: 'No content uploaded', status: 400)
    end
    @owner = params[:owner].downcase
    begin
      accept_zip(request.body, @owner) do |files|
        @transaction = Transaction.new(owner: @owner, user: current_user, files: files)
        @transaction.stash!
        @transaction.save!
      end
      start_worker
    rescue ArgumentError => e
      render status: 400, json: { status: 'JSON error', message: e.message }
    rescue StandardError => e
      render status: 500, json: { status: 'Unknown error', message: e.message }
    end
  end

  # POST /ingest/:owner ( application/json )
  def ingest_json
    @owner = params[:owner].downcase
    if request.body.size.zero?
      logger.info 'Received empty body'
      return render(text: 'No content uploaded', status: 400)
    end
    files = [accept_json(request.body, @owner, operation: 'add')]
    begin
      @transaction = Transaction.create(owner: @owner, files: files, user: current_user)
      @transaction.stash!
      @transaction.save!
      start_worker
    rescue ArgumentError => e
      render status: 400, json: { status: 'JSON error', message: e.message }
    rescue StandardError => e
      render status: 500, json: { status: 'Unknown error', message: e.message }
    end
  end

  # POST /ingest/:owner w/ multipart mime type
  def upload
    @owner = params[:owner]
    @package = params[:package]
  end

  # GET :id/filedownload/:filename
  def filedownload
    @transaction = Transaction.find(params[:id])
    name = helpers.filename_for_download
    path = helpers.path_for_download(name)
    return render(plain: 'File not found', status: 404) unless File.exist?(path)
    type = helpers.mime_type_from_filename(name)
    type ||= request.format
    # our 'json' files are streaming format, which breaks most browser
    # parsers, so force download
    send_file(path, filename: name, disposition: 'attachment', type: type)
  end

  def ingest_form
    @owner = params[:owner]
  end

  # DELETE /transactions/1
  # DELETE /transactions/1.json
  def destroy
    @transaction.destroy
    respond_to do |format|
      format.html { redirect_to transactions_url, notice: 'Transaction was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # POST /transactions/1/index
  def start_index
    @transaction = Transaction.find(params[:id])
    IndexingWorker.perform_async(@transaction.id)
    show
  end

  private

  def start_worker
    TransactionWorker.perform_async(@transaction.id)
    response.status = :accepted
    render 'ingest'
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_transaction
    @transaction = Transaction.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    raise ActionController::RoutingError, 'Not Found'
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def transaction_params
    params.permit(:view)
    params.require(:transaction).permit(:owner, :user, :status, :files)
  end
end
