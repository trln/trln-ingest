require 'spofford'

# represents a document that is stored locally and which
# can be ingested into Solr.
class DocumentsController < ApplicationController
  include Spofford::ArgotViewer
  protect_from_forgery except: :do_post
  before_action :authenticate_user!

  def index
    @documents = Document.order(:updated_at).take(10)
  end

  def search
    logger.debug "Params: #{params[:id]}"
    begin
      @doc = Document.find(params[:id])
      logger.debug "here's the doc: #{@doc}"
      show
    rescue ActiveRecord::RecordNotFound
      flash[:alert] = "Record #{params[:id]} not found"
      redirect_to(controller: 'transactions', action: 'index')
    end
  end

  def show
    @doc ||= Document.find(params[:id])
    respond_to do |format|
      format.html do
        @content = @doc.content.to_ostruct_deep
        @solr = suppress(StandardError) { fetch_solr(@doc.id) } || {}
        @enriched = suppress(StandardError) do
          prepare_for_ingest(@doc.content)
        end || {}
        @luke = suppress(StandardError) { fetch_luke_doc(@doc.id) } || {}
        if @doc.deleted?
          flash[:notice] = 'This record has been deleted.'
          if @solr.empty?
            flash[:notice] << %q{It's not currently stored in Solr}
          else
            delay = ((Time.current - @doc.updated_at) / 1.hour).round
            if delay > 1
              flash[:alert] = 'This record still appears in Solr'
            else
              flash[:notice] << "\nIt should be removed from the index soon."
            end
          end
        end
        render 'show'
      end
      format.json do
        render json: @doc.content
      end
    end
  end
end
