# frozen_string_literal: true

require 'httparty'

def value_of(array, value)
  array.nil? || array[value].nil? ? '' : array[value]
end

def uri_to_json(uri)
  JSON.parse(HTTParty.get(URI(uri)).to_s) ? JSON.parse(HTTParty.get(URI(uri)).to_s) : ''
rescue JSON::ParserError => e
  puts e
  ''
end

def recommend(author = '', subject = '')
  search_template = 'https://openlibrary.org/search.json'
  query = {
    'author': author,
    'subject': subject
  }
  search_data = JSON.parse(HTTParty.get('https://openlibrary.org/search.json', :query => query).to_s)
end
