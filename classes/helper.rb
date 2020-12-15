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

def search(search = '')
  query = {
    'q': search
  }
  search_data = uri_to_json('https://openlibrary.org/search.json', query)
  return (value_of(search_data['docs'][0], 'key')).delete!('/works/') if search_data && search_data['docs']
end

def log(msg)
  puts "[#{Time.now.to_s}] MANUAL LOG #{msg.to_s}"
end
