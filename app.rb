require 'sinatra'
require 'json'
require 'jwt'
require 'securerandom'
require 'rack/deflater'
require "sinatra/reloader" if development?

require './helpers/auth'
require './workers/create_product.rb'

# se encargare de hacerle gzip a nuestras peticiones si asi las quere el cliente
use Rack::Deflater

# simulacion de base de datos
USERS = { "user" => "clave123" }
SECRET_KEY = 'CLAVE_SECRETA'
ACCESS_TOKEN_EXPIRATION = 2 * 60 # 2 minutos
REFRESH_TOKEN_EXPIRATION = 1 * 24 * 60 * 60 # 1 dia

LOGGED_USERS = {}
PRODUCTS = {}
PRODUCTS_QUEUE = {}
REFRESH_TOKENS = {}


configure :test, :development do
  set :host_authorization, { permitted_hosts: [] }
end

post '/auth' do
  content_type :json
  begin
    data = JSON.parse(request.body.read)
    user = data["usuario"]
    password = data["contrasena"]
  rescue  Exception => e
    puts e
    halt 500, { error: "Fallo procesando tu petición" }.to_json
  end

  if USERS[user] && USERS[user] == password
    token = SecureRandom.hex(16)
    access_token = generate_access_token(user)
    refresh_token = generate_refresh_token(user)
    { access_token: access_token, refresh_token: refresh_token }.to_json
  else
    halt 404, { error: "Fallo iniciando sesión" }.to_json
  end
end

post '/refresh_token' do
  content_type :json
  begin
    data = JSON.parse(request.body.read)
    refresh_token = data["refresh_token"]
  rescue JSON::ParserError
    halt 400, { error: "JSON inválido" }.to_json
  end

  user = validate_refresh_token(refresh_token)
  halt 401, { error: "Refresh token inválido o expirado" }.to_json unless user

  access_token = generate_access_token(user)
  { access_token: access_token }.to_json
end

post '/create_product' do
  content_type :json
  require_auth

  begin
    data = JSON.parse(request.body.read)
    product_name = data["name"]
  rescue JSON::ParserError
    halt 400, { error: "JSON invalido" }.to_json
  end

  halt 400, { error: "Favor ingresa nombre para el producto" }.to_json if product_name.strip.empty? || product_name.nil?

  queue_id = SecureRandom.uuid
  PRODUCTS_QUEUE[queue_id] = {status: 'in_queue', product_id: nil}

  status 202
  body({ message: "Producto encolado para su creación", queue_id: queue_id }.to_json)

  Thread.new do
    create_product_async(queue_id, product_name)
  end
end

get '/queue_info/:queue_id' do
  content_type :json
  require_auth

  queue_id = params["queue_id"]

  halt 400, { error: "Favor ingresa el queue_id" }.to_json if queue_id.strip.empty? || queue_id.nil?

  details_queue = PRODUCTS_QUEUE[queue_id]

  halt 404, { error: "Queue id no encontrado" }.to_json if details_queue.nil?

  status 200
  if details_queue[:status] != 'done'
    body({ status_queue: details_queue[:status]}.to_json)
  else
    product = PRODUCTS[details_queue[:product_id]]
    body({ product: product }.to_json)
  end
end

get '/product/:product_id' do
  content_type :json
  require_auth

  product_id = params["product_id"]

  halt 400, { error: "Favor ingresa un product_id" }.to_json if product_id.strip.empty? || product_id.nil?

  product = PRODUCTS[product_id]

  halt 404, { error: "Producto no encontrado" }.to_json if product.nil?

  status 200
  body({ product: product }.to_json)
end


get '/AUTHORS' do
  cache_control :max_age => 24 * 3600
  send_file 'AUTHORS'
end

get '/openapi.yaml' do
  cache_control :no_store
  send_file 'openapi.yaml'
end
