require 'sinatra'
require 'json'
require 'securerandom'

# simulacion de base de datos
USERS = { "user" => "clave123" }
LOGGED_USERS = {}

PRODUCTS = {}
PRODUCTS_QUEUE = {}
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
    LOGGED_USERS[token] = user
    { token: token }.to_json
  else
    halt 404, { error: "Fallo iniciando sesión" }.to_json
  end
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



def create_product_async(queue_id, product_name)
  PRODUCTS_QUEUE[queue_id] = {status: 'processing', product_id: nil}
  sleep 5
  product_id = SecureRandom.uuid
  PRODUCTS[product_id] = { id: product_id, nombre: product_name }
  PRODUCTS_QUEUE[queue_id] = {status: 'done', product_id: product_id}
end

def is_authenticate?
  auth_header = request.env["HTTP_AUTHORIZATION"]
  return false unless auth_header

  if LOGGED_USERS[auth_header]
    true
  else
    false
  end
end

def require_auth
  return halt 401, { error: "No autenticado" }.to_json unless is_authenticate?
end
