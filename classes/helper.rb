# frozen_string_literal: true

require 'typhoeus'
require 'json'


def value_of(array, value)
  !array || array[value].nil? ? '' : array[value]
end

def uri_to_json(uri, query = nil)
  query.nil? ? JSON.parse(Typhoeus::Request.new(uri.to_s, followlocation: true, ssl_verifypeer: false).run.body) : JSON.parse(Typhoeus::Request.new(uri.to_s, params: query, followlocation: true, ssl_verifypeer: false).run.body)
# rescue HTTParty::ResponseError => e
#   log(e)
#   false
rescue JSON::ParserError => e
  log('JSON ParserError!')
  false
end

def recommend(author = '', subject = '')
  query = {
    'author': author,
    'subject': subject
  }
  uri_to_json('https://openlibrary.org/search.json', query)
end

def search(search = '', limit = 10)
  query = {
    'q': search,
    'limit': limit
  }
  search_data = uri_to_json('https://openlibrary.org/search.json', query)

  book_ids = search_data['docs'].map do |result|
    value_of(value_of(result, 'isbn'), 0).delete('/books/')
  end
end

$goodreads_key = nil
def set_goodreads_key
  return $goodreads_key unless $goodreads_key.nil?

  goodreads_path = 'db/goodreads.json'
  $goodreads_key = (JSON.parse(File.open(goodreads_path).read))['apikey'] if File.exist?(goodreads_path)
  return $goodreads_key unless $goodreads_key.nil? || $goodreads_key == ''

  warn "Goodreads key not found! Rating not retrievable. Enter it in #{goodreads_path} as a JSON with value 'apikey'"
end

def log(msg)
  puts "[#{Time.now}] MANUAL LOG #{msg}"
end
