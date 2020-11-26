#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/json'
require 'webrick'
require 'webrick/https'
require 'openssl'

load 'classes/users.rb'
load 'classes/book.rb'

webrick_options = {
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
  # set :environment, :production
  enable :sessions
  users = Users.new
  users.write_every('3s')

  get '/' do
    erb :index
  end

  post '/register' do
    if params.key?(:name) && params.key?(:pass) && users.add(params[:name], params[:pass])
      'Success!'
    else
      halt 400, 'Bad request.'
    end
  end

  post '/login' do
    if params.key?(:name) && params.key?(:pass) && users.login(params[:name], params[:pass])
      session[:id] = params[:name]
      redirect '/'
    else
      halt 401, 'Access denied. Have you entered a correct username and password?'
    end
  end

  get '/signout' do
    session.delete(:id)
  end

  get '/book/:book' do
    if session[:id]
      b = Book.new(params[:book]) if params.key?(:book)
      json b.to_hash
    else
      halt 401, 'Access denied.'
    end
  end

  get '/book/:book/:param' do
    if session[:id]
      b = Book.new(params[:book]) if params.key?(:book)
      b.instance_variable_get(params[:param]) if b.instance_variable_defined?(params[:param])
    else
      halt 401, 'Access denied.'
    end
  end
end

Rack::Handler::WEBrick.run MyReadServer, webrick_options
# vim: tabstop=2 shiftwidth=2 expandtab
