require 'spofford'

class TransactionsController < ApplicationController
  before_action :set_transaction, only: [:show, :edit, :update, :destroy]

  # GET /transactions
  # GET /transactions.json
  def index
    @transactions = Transaction.all
  end

  # GET /transactions/1
  # GET /transactions/1.json
  def show
  end

  # GET /transactions/new
  def new
    @transaction = Transaction.new
  end

  # GET /transactions/1/rerun
  def edit
    return start_worker
  end

  protect_from_forgery except: [ :ingest_json, :ingest_zip ]

  # POST /ingest/:owner ( application/zip )
  def ingest_zip
    @owner = params[:owner]
    Spofford::IngestHelper::accept_zip(request.raw_post, @owner) do |files|
      @transaction = Transaction.new(owner: @owner, files: files)
      @transaction.stash!
      @transaction.save!
    end
    start_worker
  end

  # POST /ingest/:owner ( application/json )
  def ingest_json
    @owner = params[:owner]
    files = [ Spofford::IngestHelper::accept_json(request.body, @owner, operation: 'add') ]
    @transaction = Transaction.create(owner: @owner, files: files)
    @transaction.stash!
    @transaction.save!
    start_worker
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

  private

    def start_worker
      TransactionWorker.perform_async(@transaction.id)
      response.status = :accepted
      render 'ingest'
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_transaction
      @transaction = Transaction.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def transaction_params
      params.require(:transaction).permit(:owner, :user, :status, :files)
    end
end
