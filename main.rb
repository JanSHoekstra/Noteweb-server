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
require 'parallel'

require_relative 'classes/users'
require_relative 'classes/book'
require_relative 'classes/helper'

webrick_options = {
  Host: '0.0.0.0',
  Port: ENV['PORT'],
  Logger: WEBrick::Log.new($stderr, WEBrick::Log::DEBUG),
  DocumentRoot: '/ruby/htdocs',
  # SSLEnable: true,
  # SSLVerifyClient: OpenSSL::SSL::VERIFY_NONE,
  # SSLCertificate: OpenSSL::X509::Certificate.new(File.open('alt.cert').read),
  # SSLPrivateKey: OpenSSL::PKey::RSA.new(File.open('alt.key').read),
  # SSLCertName: [['CN', WEBrick::Utils.getservername]]
}

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

  # Create a new database in memory for the users, sync them to file every three seconds
  users = Users.new
  users.write_every('3s')

  # Books cache - store books in RAM when they have already been fetched.
  # Cache for a book is refreshed if it is requested 24 hours after creation of the cache for the specified book
  books = {}

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
  post '/user/:name/change_password' do
    if !params[:name].nil? && !params[:old_pass].nil? && !params[:new_pass].nil?
      if params[:name] == session[:id]
        users.chpass(params[:name], params[:old_pass], params[:new_pass]) ? status(200) : halt(401)
      else
        halt 401
      end
    else
      halt 400
    end
  end

  # Delete users account, need to be logged in as specified user
  post '/user/:name/delete' do
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
  get '/user/:name/book_collections' do
    if users.exists?(params[:name]) && params[:name] == session[:id]
      json users.users[params[:name]][1]
    else
      halt 401
    end
  end

  # Add book to book collection, need to be logged in as specified user
  get '/user/:name/add_book_to_collection/:collection_name/:book_id' do
    if users.exists?(params[:name]) && params[:name] == session[:id]
      users.add_book_to_collection(params[:name], params[:collection_name], params[:book_id])
    else
      halt 401
    end
  end

  # Delete book from book collection, need to be logged in as specified user
  get '/user/:name/del_book_from_collection/:collection_name/:book_id' do
    if users.exists?(params[:name]) && params[:name] == session[:id]
      users.add_book_to_collection(params[:name], params[:collection_name], params[:book_id])
    else
      halt 401
    end
  end

  # Create new book collection, need to be logged in as specified user
  get '/user/:name/add_book_collection/:collection_name' do
    if users.exists?(params[:name]) && params[:name] == session[:id]
      users.add_collection(params[:name], params[:collection_name]) ? status(201) : halt(400)
    else
      halt 401
    end
  end

  # Create new book collection with books (separated by ;), need to be logged in as specified user
  get '/user/:name/add_book_collection/:collection_name/:book_ids' do
    if users.exists?(params[:name]) && params[:name] == session[:id]
      book_ids = params[:book_ids].to_s.split(';') unless params[:book_ids].nil?
      users.add_collection(params[:name], params[:collection_name], book_ids) ? status(201) : halt(400)
    else
      halt 401
    end
  end

  # Delete book collection, need to be logged in as specified user
  get '/user/:name/del_book_collection/:collection_name' do
    if users.exists?(params[:name]) && params[:name] == session[:id]
      users.del_collection(params[:name], params[:collection_name]) ? status(200) : halt(400)
    else
      halt 401
    end
  end

  # Rename book collection, need to be logged in as specified user
  get '/user/:name/chname_book_collection/:collection_name/:new_collection_name' do
    if users.exists?(params[:name]) && params[:name] == session[:id]
      users.chname_collection(params[:name], params[:collection_name], params[:new_collection_name]) ? status(200) : halt(400)
    else
      halt 401
    end
  end

  # Get book collection by name from user, need to be logged in as specified user
  get '/user/:name/book_collections/:book_collection' do
    session[:id] && params[:name] == session[:id] ? json(users.get_collection(params[:name], params[:book_collection])) : halt(401)
  end

  # Search for books, need to be logged in
  get '/search_book/:search' do
    if session[:id]
      book_ids = search(params[:search])

      halt 400 if !book_ids

      # Launch a thread per Book ID to retrieve details about this book, results in much faster execution
      books_to_return = Parallel.map(book_ids) do |book_id|
        Book.new(book_id).to_hash
      end

      json books_to_return
    else
      halt 401
    end
  end

  # Recommend a book based on author and subject(s - can be an array), need to be logged in
  get '/recommend_book_via_author/:author' do
    session[:id] ? json(recommend(params[:author])) : halt(401)
  end

  get '/recommend_book_via_subject/:subject' do
    session[:id] ? json(recommend('', params[:subject])) : halt(401)
  end

  get '/recommend_book_via_author_subject/:author/:subject' do
    session[:id] ? json(recommend(params[:author], params[:subject])) : halt(401)
  end

  # Get book information via id, need to be logged in
  get '/book/:book' do
    halt 400 if params[:book].nil?
    if session[:id]
      # Use book cache, refresh cache if the current book cache is older than 24 hours (86400s)
      books[params[:book]] = [Book.new(params[:book]), Time.now] if books[params[:book]].nil? || (Time.now - books[params[:book]][1]) > 86400
      json (books[params[:book]])[0].to_hash
    else
      halt 401
    end
  end

  # Get data entry from book, need to be logged in
  get '/book/:book/:param' do
    if session[:id]
      books[params[:book]] ||= [Book.new(params[:book]), Time.now] unless params[:book].nil?
      b = books[params[:book]][0]
      b.instance_variable_get(params[:param]) if b.instance_variable_defined?(params[:param])
    else
      halt 401
    end
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
