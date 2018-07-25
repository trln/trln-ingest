require 'json'

module DocumentsHelper
  def pretty_json(content)
    JSON.pretty_generate(content)
  end

  def main_title(content)
    return '[not present]' if content.nil?
    begin
      content.title_main.first.value
    rescue StandardError
      '[not found]'
    end
  end

  def isbns(content)
    return '' if content.nil?
    return '' if content.try(:isbn).nil?
    begin
      content.isbn.map do |isbn|
        isbn.number + ( isbn.qualifying_info ? " #{isbn.qualifying_info}" : '' )
      end.join(', ')
    rescue StandardError
      '[unable to retrieve]'
    end
  end
end
