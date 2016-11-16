require 'json'

module DocumentsHelper

  def pretty_json(document)
    JSON.pretty_generate(document.content)
  end
end