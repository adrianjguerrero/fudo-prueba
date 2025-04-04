require 'sinatra'
require 'json'
require 'securerandom'



# simulacion de base de datos
USERS = { "user" => "clave123" }
LOGGED_USERS = {}
PRODUCTS = {}


post '/auth' do
  content_type :json

  begin
    params_request = JSON.parse(request.body.read)
    user = params_request["usuario"]
    password = params_request["contrasena"]
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




def is_authenticate?
  auth_header = request.env["HTTP_AUTHORIZATION"]
  puts LOGGED_USERS
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