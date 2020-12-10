#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/json'
require 'webrick'
require 'webrick/https'
require 'openssl'
require 'rack/throttle'

require_relative 'classes/users.rb'
require_relative 'classes/book.rb'
require_relative 'classes/helper.rb'

webrick_options = {
  Host: '0.0.0.0',
  Port: 2048,
  Logger: WEBrick::Log.new($stderr, WEBrick::Log::DEBUG),
  DocumentRoot: '/ruby/htdocs',
  SSLEnable: true,
  SSLVerifyClient: OpenSSL::SSL::VERIFY_NONE,
  SSLCertificate: OpenSSL::X509::Certificate.new(File.open('alt.cert').read),
  SSLPrivateKey: OpenSSL::PKey::RSA.new(File.open('alt.key').read),
  SSLCertName: [['CN', WEBrick::Utils.getservername]]
}

# The server
class MyReadServer < Sinatra::Base
  # Set up logger
  logging_path = 'db/server.log'
  Dir.mkdir('db') unless Dir.exist?('db')
  File.new(logging_path, 'w').close unless File.exist?(logging_path)
  $stdout.reopen(logging_path, 'w')
  $stdout.sync = true
  $stderr.reopen($stdout)

  # Configure rate limiting - 10 POST requests an hour
  rules = [
    { method: 'POST', limit: 10 }
    # { method: 'GET', limit: 10 },
  ]
  ip_whitelist = [
    '127.0.0.1',
    '0.0.0.0'
  ]
  configure :development, :production do
    use Rack::Throttle::Rules, rules: rules, ip_whitelist: ip_whitelist, time_window: :hour
  end

  # set :environment, :production

  # Enable Sinatra session storage, sessions are reset after 1800 seconds (30 min)
  enable :sessions
  set :sessions, :expire_after => 1800

  users = Users.new
  users.write_every('3s')

  # Books cache - store books in RAM when they have already been fetched
  books = {}

  get '/' do
    erb :index
  end

  post '/register' do
    if params.key?(:name) && params.key?(:pass) && users.add(params[:name], params[:pass])
      'Success!'
    else
      halt 400, 'Bad request. Make sure the password contains at least 9 characters (max 64), 1 upper- and lowercase letter, a digit, a special character and doesn\'t include the username.<br><img src="https://http.cat/400">'
    end
  end

  post '/login' do
    if params.key?(:name) && params.key?(:pass) && users.login(params[:name], params[:pass])
      session[:id] = params[:name]
      redirect '/'
    else
      halt 401, 'Access denied. Have you entered a correct username and password?<br><img src="https://http.cat/401">'
    end
  end

  get '/signout' do
    session.delete(:id)
    redirect '/'
  end

  get '/user/:name' do
    if users.exists?(params[:name]) && params[:name] == session[:id]
      "Hello #{params[:name]}!"
    else
      halt 401, 'Access denied. <br><img src="https://http.cat/401">'
    end
  end

  get '/user/:name/book_collections' do
    if users.exists?(params[:name]) && params[:name] == session[:id]
      json users.users[params[:name]][1]
    else
      halt 401, 'Access denied. <br><img src="https://http.cat/401">'
    end
  end

  get '/user/:name/book_collections/add/:collection_name/:book_ids' do
    if users.exists?(params[:name]) && params[:name] == session[:id]
      book_ids = params[:book_ids].to_s.split(';')
      if users.add_collection(params[:name], params[:collection_name], book_ids)
        "Book collection #{params[:collection_name]} has been added to the library of #{params[:name]}!"
      else
        "Failed to add book collection '#{params[:collection_name]}'! The collection name may already be in use."
      end
    else
      halt 401, 'Access denied. <br><img src="https://http.cat/401">'
    end
  end

  get '/user/:name/book_collections/del/:collection_name' do
    if users.exists?(params[:name]) && params[:name] == session[:id]
      if users.del_collection(params[:name], params[:collection_name])
        "Book collection #{params[:collection_name]} has been removed from the library of #{params[:name]}"
      else
        "Failed to add book collection '#{params[:collection_name]}'! The collection name may not exist."
      end
    else
      halt 401, 'Access denied. <br><img src="https://http.cat/401">'
    end
  end

  get '/book/:book' do
    if session[:id]
      books[params[:book]] ||= Book.new(params[:book]) if params.key?(:book)
      json books[params[:book]].to_hash
    else
      halt 401, 'Access denied.<br><img src="https://http.cat/401">'
    end
  end

  get '/book/:book/:param' do
    if session[:id]
      books[params[:book]] ||= Book.new(params[:book]) if params.key?(:book)
      b = books[params[:book]]
      b.instance_variable_get(params[:param]) if b.instance_variable_defined?(params[:param])
    else
      halt 401, 'Access denied.<br><img src="https://http.cat/401">'
    end
  end

  get '/search/:search' do
    if session[:id]
      json search(params[:search])
    else
      halt 401, 'Access denied.<br><img src="https://http.cat/401">'
    end
  end

  get '/recommend/:author/:subject' do
    if session[:id]
      json recommend(params[:author], params[:subject])
    else
      halt 401, 'Access denied.<br><img src="https://http.cat/401">'
    end
  end

  not_found do
    halt 404, 'Page not found.<br><img src="https://http.cat/404">'
  end
end

Rack::Handler::WEBrick.run MyReadServer, webrick_options
# vim: tabstop=2 shiftwidth=2 expandtab
