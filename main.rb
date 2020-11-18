#!/usr/bin/env ruby

require 'sinatra/base'
require 'sinatra/json'
require 'webrick'
require 'webrick/https'
require 'openssl'

webrick_options = {
    :Port               => 443,
    :Logger             => WEBrick::Log::new($stderr, WEBrick::Log::DEBUG),
    :DocumentRoot       => "/ruby/htdocs",
    :SSLEnable          => true,
    :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
    :SSLCertificate     => OpenSSL::X509::Certificate.new(File.open("alt.cert").read),
    :SSLPrivateKey      => OpenSSL::PKey::RSA.new(        File.open("alt.key").read),
    :SSLCertName        => [ [ "CN",WEBrick::Utils::getservername ] ]
}

class MyServer < Sinatra::Base
    get '/' do
        json text: "Hellow, world!"
    end

    get '/hello' do
        json lol: "bye"
    end
end

Rack::Handler::WEBrick.run MyServer, webrick_options
