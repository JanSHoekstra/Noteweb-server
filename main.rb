#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/json'
require 'webrick'
require 'webrick/https'
require 'openssl'
require 'json'
require 'rufus-scheduler'

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

$users_path = 'db/users.json'
$users = JSON.parse(File.open($users_path).read)

def write_users_to_file
  unless $users.empty?
    File.write($users_path, JSON.pretty_generate($users))
    puts 'Writing $users to file.'
  end
end

scheduler = Rufus::Scheduler.new
scheduler.every '10s' do
  write_users_to_file
end

# The server
class MyServer < Sinatra::Base
  # set :environment, :production

  get '/' do
    json text: 'Hellow, world!'
  end

  get '/hello' do
    json lol: 'bye'
  end

  post '/login' do
    if params.key?(:name) && params.key?(:pass)
      # Save name and pass to $users variable
      if $users.key?(params[:name])
        json text: 'Username already exists!'
      else
        $users[params[:name]] = [params[:pass], 'salt']
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
