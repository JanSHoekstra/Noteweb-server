# frozen_string_literal: true

require 'json'
require 'rufus-scheduler'
require 'bcrypt'
require 'httparty'

# The Books API to fetch info about books
class Books
  def initialize
    @works_path = 'https://openlibrary.org/works/'
  end

  def get_book(ol_id)
    uri = URI(@works_path + ol_id + '.json')
    response = HTTParty.get(uri)
    response.to_s
  end

  def get_amazon_link_from_book(ol_id)
    amazon_id = JSON.parse(get_book(ol_id))['identifiers']['amazon'].to_s
    amazon_id.delete! '["]'
    'https://www.amazon.com/dp/' + amazon_id
  end
end
