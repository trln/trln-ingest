require 'spofford'

# Controller for managing transactions
class TransactionsController < ApplicationController
  include Spofford::IngestHelper
  protect_from_forgery except: %i[ingest_json ingest_zip]
  acts_as_token_authentication_handler_for User, only: %i[ingest_zip ingest_json], fallback: :exception

  before_action :authenticate_user!
  before_action :set_transaction, only: %i[show edit update destroy]

  # GET /transactions
  # GET /transactions.json
  def index
    @transactions = Transaction.paginate(page: params[:page], per_page: 25).order('created_at DESC')
  end

  # GET /transactions/1
  # GET /transactions/1.json
  def show
    @document_ids = Document.where(txn: @transaction).select(:id, :local_id)
  end

  # GET /transactions/1/edit
  def edit
    start_worker
  end

  # POST /ingest/:owner ( application/zip )
  def ingest_zip
    if request.body.size.zero?
      logger.info('Received empty body')
      return render(text: 'No content uploaded', status: 400)
    end
    @owner = params[:owner]
    begin
      accept_zip(request.body, @owner) do |files|
        @transaction = Transaction.new(owner: @owner, files: files)
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
    @owner = params[:owner]
    if request.body.size.zero?
      logger.info 'Received empty body'
      return render(text: 'No content uploaded', status: 400)
    end
    files = [accept_json(request.body, @owner, operation: 'add')]
    begin
      @transaction = Transaction.create(owner: @owner, files: files, user: current_user.id)
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
    logger.debug("here we are in upload with content type " + request.headers['Content-Type'])
    @owner = params[:owner]
    @package = params[:package]
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
    params.require(:transaction).permit(:owner, :user, :status, :files)
  end
end
