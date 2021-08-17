#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/json'
require 'webrick'
require 'webrick/https'
require 'openssl'
require 'rack/throttle'
require 'rack/protection'
require 'rack/session/encrypted_cookie'
require 'securerandom'
require 'slop'
require 'moneta'

require_relative 'classes/users'
require_relative 'classes/helper'

if File.exist?('/etc/letsencrypt/live/socialread.tk/fullchain.pem')
  webrick_options = {
    Host: '0.0.0.0',
    Port: 2048,
    Logger: WEBrick::Log.new($stderr, WEBrick::Log::DEBUG),
    DocumentRoot: '/ruby/htdocs',
    SSLEnable: true,
    SSLVerifyClient: OpenSSL::SSL::VERIFY_NONE,
    SSLCertificate: OpenSSL::X509::Certificate.new(File.open('/etc/letsencrypt/live/socialread.tk/fullchain.pem').read),
    SSLPrivateKey: OpenSSL::PKey::RSA.new(File.open('/etc/letsencrypt/live/socialread.tk/privkey.pem').read),
    SSLCertName: [['CN', WEBrick::Utils.getservername]]
  }
else
  webrick_options = {
    Host: '0.0.0.0',
    Port: 2048,
    Logger: WEBrick::Log.new($stderr, WEBrick::Log::DEBUG),
    DocumentRoot: '/ruby/htdocs',
    SSLEnable: false
  }
end

# The server
class MyReadServer < Sinatra::Base
  # Accept command-line arguments for easy configuration
  @arguments = Slop.parse do |o|
    o.on '-h', '--help' do
      puts o
      exit
    end
    o.string '-l', '--limit', '(optional) specify the maximum hourly amount of POST requests allowed per user', default: 10
    o.bool '-p', '--production', 'run the server in production mode', default: false
  end

  # Set up logging
  logging_path = 'db/server.log'
  Dir.mkdir('db') unless Dir.exist?('db')
  File.new(logging_path, 'w').close unless File.exist?(logging_path)
  $stdout.reopen(logging_path, 'w')
  $stdout.sync = true
  $stderr.reopen($stdout)

  # Configure rate limiting
  rules = [
    { method: 'POST', limit: @arguments[:limit]}
    # { method: 'GET', limit: 10 },
  ]

  # IP Whitelist - only works when running server in development environment
  ip_whitelist = [
    '127.0.0.1',
    '0.0.0.0'
  ]

  # Enable production environment when specified
  set :environment, :production if @arguments.production?

  # Configure the following rules for production environment
  configure :production do
    use Rack::Throttle::Rules, rules: rules, time_window: :hour
    use Rack::Protection
  end

  # Configure the following rules for production environment (IP Whitelist is on)
  configure :development do
    use Rack::Throttle::Rules, rules: rules, ip_whitelist: ip_whitelist, time_window: :hour
    use Rack::Protection
  end

  # Enable (encrypted) Sinatra session storage, sessions are reset after 1800 seconds (30 min)
  enable :sessions
  set :sessions, key_size: 32, salt: SecureRandom.hex(32), signed_salt: SecureRandom.hex(32)
  set :session_store, Rack::Session::EncryptedCookie
  set :sessions, expire_after: 1800
  set force_ssl: true

  # Create a database object
  users = Users.new

  # #############
  # API Endpoints
  # #############

  # Home
  get '/' do
    erb :index
  end

  # Register
  post '/register' do
    !params[:name].nil? && !params[:pass].nil? && users.add(params[:name], params[:pass]) ? status(201) : halt(400)
  end

  # Login
  post '/login' do
    if !params[:name].nil? && !params[:pass].nil? && users.login(params[:name], params[:pass])
      session[:id] = params[:name]
      redirect '/'
    else
      halt 401
    end
  end

  # Sign out
  get '/signout' do
    session.delete(:id)
    redirect '/'
  end

  # Will return 200 if logged in as this user
  get '/user/:name' do
    users.exists?(params[:name]) && params[:name] == session[:id] ? status(200) : halt(401)
  end

  # Change password for user, need to be logged in as specified user
  post '/user/change_password' do
    if !params[:name].nil? && !params[:old_pass].nil? && !params[:new_pass].nil?
      users.chpass(params[:name], params[:old_pass], params[:new_pass]) ? status(200) : halt(401)
    else
      halt 400
    end
  end

  # Delete users account, need to be logged in as specified user
  post '/user/delete' do
    if !params[:name].nil? && !params[:pass].nil?
      if params[:name] == session[:id]
        if users.del(params[:name], params[:pass])
          session.delete(:id)
          status 200
        else
          halt 401
        end
      else
        halt 401
      end
    else
      halt 400
    end
  end

  # Get book collections from user, need to be logged in as specified user
  get '/user/book_collections' do
    if users.exists?(params[:name]) && params[:name] == session[:id]
      json users.users[params[:name]][1]
    else
      halt 401
    end
  end

  # Create note
  post '/note' do

  end

  # Get note with nid from personal notes
  get '/note/:nid' do

  end

  # Delete note with id <nid>
  delete '/note/:nid' do

  end

  # ##############
  # Error Handling
  # ##############

  # 201 - Created
  error 201 do
    erb :error, locals: { message: body[0], response_code: 201 }
  end

  # 400 - Bad Request
  error 400 do
    erb :error, locals: { message: body[0], response_code: 400 }
  end

  # 401 - Unauthorized
  error 401 do
    erb :error, locals: { message: body[0], response_code: 401 }
  end
end

Rack::Handler::WEBrick.run MyReadServer, webrick_options
