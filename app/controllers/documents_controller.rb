class DocumentsController < ApplicationController

    protect_from_forgery except: :do_post

    def index
        @documents = Document.order(:updated_at).take(10)
    end

    def show
        @doc = Document.find(params[:id])
        respond_to do |format|
            format.html {
                @content = @doc.content.to_ostruct_deep
                render 'show'
            }
            format.json {
                render json: @doc.content }
        end
    end
end