# frozen_string_literal: true

require 'httparty'
require 'json'

def value_of(array, value)
  !array || array[value].nil? ? '' : array[value]
end

def uri_to_json(uri, query = nil)
  if query.nil?
    JSON.parse(HTTParty.get(uri.to_s).to_s)
  else
    JSON.parse(HTTParty.get(uri.to_s, query: query).to_s)
  end
rescue HTTParty::ResponseError, JSON::ParserError => e
  log(e)
  false
end

def recommend(author = '', subject = '')
  query = {
    'author' => author,
    'subject' => subject
  }
  uri_to_json('https://openlibrary.org/search.json', query)
end

def search(search = '')
  query = {
    'q' => search
  }
  uri_to_json('https://openlibrary.org/search.json', query)
end

def log(msg)
  puts '[' + Time.now.to_s + '] LOG   ' + msg.to_s
end
