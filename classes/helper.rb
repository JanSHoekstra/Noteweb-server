# frozen_string_literal: true

require 'httparty'
require 'json'

def value_of(array, value)
  !array || array[value].nil? ? '' : array[value]
end

def uri_to_json(uri, query = nil)
  query.nil? ? JSON.parse(HTTParty.get(uri.to_s).to_s) : JSON.parse(HTTParty.get(uri.to_s, query: query).to_s)
rescue HTTParty::ResponseError, JSON::ParserError => e
  log(e)
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

  book_ids = []
  search_data['docs']&.each_with_index do |result, i|
    book_ids.push(value_of(result, 'key').delete('/works/'))
    return book_ids if i >= limit
  end
  return book_ids
end

def log(msg)
  puts "[#{Time.now}] MANUAL LOG #{msg}"
end
