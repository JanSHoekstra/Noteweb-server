#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/json'
require 'webrick'
require 'webrick/https'
require 'openssl'

load 'classes/users.rb'

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

  get '/' do
    json text: 'Hellow, world!'
  end

  get '/hello' do
    json lol: 'bye'
  end

  post '/login' do
    if params.key?(:name) && params.key?(:pass)
      # Save name and pass to $users variable
      if users.exists?(params[:name])
        json text: 'Username already exists!'
      else
        users.add(params[:name], params[:pass])
        # debug
        puts 'Adding user to $users'
        json text: 'Success!'
      end
    else
      json text: 'Bad request!'
    end
  end
end

Rack::Handler::WEBrick.run MyServer, webrick_options
# vim: tabstop=2 shiftwidth=2 expandtab
