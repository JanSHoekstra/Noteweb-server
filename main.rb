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

  def http_code(response_code)
    @response_code = response_code
    erb :error
  end

  get '/' do
    erb :index
  end

  post '/register' do
    if params.key?(:name) && params.key?(:pass) && users.add(params[:name], params[:pass])
      http_code 201
    else
      http_code 400
    end
  end

  post '/login' do
    if params.key?(:name) && params.key?(:pass) && users.login(params[:name], params[:pass])
      session[:id] = params[:name]
      redirect '/'
    else
      http_code 401
    end
  end

  get '/signout' do
    session.delete(:id)
    redirect '/'
  end

  get '/user/:name' do
    if users.exists?(params[:name]) && params[:name] == session[:id]
      http_code 200
    else
      http_code 401
    end
  end

  post '/user/:name/change_password' do
    if params.key?(:name) && params.key?(:new_pass) && params.key?(:old_pass)
      if params[:name] == session[:id]
        if users.chpass(name, old_pass, new_pass)
          http_code 200
        else
          http_code 400
        end
      else
        http_code 401
      end
    else
      http_code 400
    end
  end

  get '/user/:name/book_collections' do
    if users.exists?(params[:name]) && params[:name] == session[:id]
      json users.users[params[:name]][1]
    else
      http_code 401
    end
  end

  get '/user/:name/add_book_collection/:collection_name' do
    if users.exists?(params[:name]) && params[:name] == session[:id]
      if users.add_collection(params[:name], params[:collection_name])
        http_code 201
      else
        http_code 500
      end
    else
      http_code 401
    end
  end

  get '/user/:name/add_book_collection/:collection_name/:book_ids' do
    if users.exists?(params[:name]) && params[:name] == session[:id]
      book_ids = params[:book_ids].to_s.split(';') unless params[:book_ids].nil?
      if users.add_collection(params[:name], params[:collection_name], book_ids)
        http_code 201
      else
        http_code 500
      end
    else
      http_code 401
    end
  end

  get '/user/:name/del_book_collection/:collection_name' do
    if users.exists?(params[:name]) && params[:name] == session[:id]
      if users.del_collection(params[:name], params[:collection_name])
        http_code 200
      else
        http_code 500
      end
    else
      http_code 401
    end
  end

  get '/user/:name/chname_book_collection/:collection_name/:new_collection_name' do
    if users.exists?(params[:name]) && params[:name] == session[:id]
      if users.chname_collection(params[:name], params[:collection_name], params[:new_collection_name])
        http_code 200
      else
        http_code 500
      end
    else
      http_code 401
    end
  end

  get '/user/:name/book_collections/:book_collection' do
    if session[:id]
      json users.get_collection(params[:name], params[:book_collection])
    else
      http_code 401
    end
  end

  get '/search_book/:search' do
    if session[:id]
      json search(params[:search])
    else
      http_code 401
    end
  end

  get '/recommend_book/:author/:subject' do
    if session[:id]
      json recommend(params[:author], params[:subject])
    else
      http_code 401
    end
  end

  get '/book/:book' do
    if session[:id]
      books[params[:book]] ||= Book.new(params[:book]) if params.key?(:book)
      json books[params[:book]].to_hash
    else
      http_code 401
    end
  end

  get '/book/:book/:param' do
    if session[:id]
      books[params[:book]] ||= Book.new(params[:book]) if params.key?(:book)
      b = books[params[:book]]
      b.instance_variable_get(params[:param]) if b.instance_variable_defined?(params[:param])
    else
      http_code 401
    end
  end
end

Rack::Handler::WEBrick.run MyReadServer, webrick_options
# vim: tabstop=2 shiftwidth=2 expandtab
