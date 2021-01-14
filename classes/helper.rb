# frozen_string_literal: true

require 'typhoeus'
require 'json'

def value_of(array, value)
  !array || array[value].nil? ? '' : array[value]
end

def uri_to_json(uri, query = nil)
  query.nil? ? JSON.parse(Typhoeus::Request.new(uri.to_s, followlocation: true, ssl_verifypeer: false).run.body) : JSON.parse(Typhoeus::Request.new(uri.to_s, params: query, followlocation: true, ssl_verifypeer: false).run.body)
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

def recommend_personal(user)
  book1 = 'OL11077267W'
  book2 = 'OL11077267W'
  book3 = 'OL11077267W'

  # user[1].each do |bookcol|
  #  bookcol.books[0] # :author :subjects

  [book1, book2, book3]
end

$search_cache = {}
def search(search = '', limit = 10)
  # Return cached result if available
  current_time = Time.now
  search.lowercase!
  return $search_cache[search][0] unless $search_cache[search].nil? || (current_time - $search_cache[search][1]) > 86_400

  # Else query this search query on openlibrary
  query = {
    'q': search,
    'limit': limit
  }
  search_data = uri_to_json('https://openlibrary.org/search.json', query)

  # Get the ISBNs for each result
  search_result = search_data['docs'].filter_map do |result|
    value_of(value_of(result, 'isbn'), 0).delete('/books/') unless value_of(value_of(result, 'isbn'), 0) == ''
  end

  # Set the cache for this query and return it
  $search_cache[search] = [search_result, current_time]
  return $search_cache[search][0]
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
