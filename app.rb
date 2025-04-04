require 'sinatra'
require 'json'
require 'securerandom'



# simulacion de base de datos
USERS = { "user" => "clave123" }
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
    { token: token }.to_json
  else
    halt 404, { error: "Fallo iniciando sesión" }.to_json
  end
end