require 'faraday'
require 'faraday-cookie_jar'

@connection = Faraday.new(
  'https://0.0.0.0:2048/',
  ssl: { verify: false }
) do |builder|
  builder.use :cookie_jar
end
# p connection.get '/user/lolwutbanaan'

@char_range = (?!..?~).to_a
def mutate!(string)
  random_location = rand(string.length)
  string[random_location] = @char_range[rand(@char_range.count)]

  if rand(10) > 5 then string.concat(@char_range[rand(@char_range.count)]) end
  return string
end

def test_login(name, pass)
  response = @connection.post '/login' do |req|
    req.headers[:content_type] = 'application/json'
    req.params[:name] = name
    req.params[:pass] = pass
  end
  if response.status != 401
    p response
  end
end
def test_register(name, pass)
  response = @connection.post '/register' do |req|
    req.headers[:content_type] = 'application/json'
    req.params[:name] = name
    req.params[:pass] = pass
  end
  if response.status == 201 || response.status == 400 then return true end

  p response
end

def register(name, pass)
# succes = 201, unsuccesful = 400
  response = @connection.post '/register' do |req|
    req.headers[:content_type] = 'application/json'
    req.params[:name] = name
    req.params[:pass] = pass
  end
  if response.status == 201 then return true end

  p response
end
def login(name, pass)
  response = @connection.post '/login' do |req|
    req.headers[:content_type] = 'application/json'
    req.params[:name] = name
    req.params[:pass] = pass
  end
  if response.status != 303
    register(name, pass)
    login(name, pass)
  end
end

def accountmgmt(name, correctname)
  response = @connection.post "/user/#{name}" do |req|
    req.headers[:content_type] = 'application/json'
  end
  unless name == correctname && response.status == 200 || name != correctname && response.status == 404
    p response
  end
end
