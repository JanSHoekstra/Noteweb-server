#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/json'
require 'webrick'
require 'webrick/https'
require 'openssl'

load 'classes/users.rb'
load 'classes/books.rb'

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
class MyServer < Sinatra::Base
  # set :environment, :production
  users = Users.new
  users.write_every('3s')

  books = Books.new

  post '/register' do
    if params.key?(:name) && params.key?(:pass) && users.add(params[:name], params[:pass])
      json text: 'Success!'
    else
      json text: 'Bad request!'
    end
  end

  post '/login' do
    if params.key?(:name) && params.key?(:pass) && users.login(params[:name], params[:pass])
      json text: 'Succesful login!'
    else
      json text: 'Login denied!'
    end
  end
  
  post '/books/get' do
    books.get_book(params[:book]) if params.key?(:book)
  end

  post '/books/get/amazon_link' do
    books.get_amazon_link_from_book(params[:book]) if params.key?(:book)
  end
end

Rack::Handler::WEBrick.run MyServer, webrick_options
# vim: tabstop=2 shiftwidth=2 expandtab
