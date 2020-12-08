# frozen_string_literal: true

require 'httparty'
require 'json'

def value_of(array, value)
  !array || array[value].nil? ? '' : array[value]
end

def uri_to_json(uri)
  JSON.parse(HTTParty.get(URI(uri)).to_s)
rescue HTTParty::ResponseError => e
  puts e
  false
rescue JSON::ParserError => e
  puts e
  false
end

def recommend(author = '', subject = '')
  query = {
    'author': author,
    'subject': subject
  }
  JSON.parse(HTTParty.get(site: 'https://openlibrary.org/search.json', query: query).to_s)
end

def log(msg)
  puts '[' + Time.now.to_s + '] LOG   ' + msg.to_s
end
