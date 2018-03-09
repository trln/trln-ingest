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
    logger.info "Params: #{params[:id]}"
    begin
      @doc = Document.find(params[:id])
      logger.info "here's the doc: #{@doc}"
      show
    rescue ActiveRecord::RecordNotFound
      not_found
    end
  end

  def show
    @doc ||= Document.find(params[:id])
    respond_to do |format|
      format.html do
        @content = @doc.content.to_ostruct_deep
        @solr = fetch_solr(@doc.id)
        @enriched = prepare_for_ingest(@doc.content)
        render 'show'
      end
      format.json do
        render json: @doc.content
      end
    end
  end
end
