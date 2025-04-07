require_relative '../app'
require "rack/test"
require "rspec"

ENV['RACK_ENV'] = 'test'

RSpec.describe "Pruebas de endpoint" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  let(:valid_user) { { usuario: "user", contrasena: "clave123" } }
  let(:invalid_user) { { usuario: "usuario", contrasena: "error" } }

  describe "POST /auth" do
    it "logea usuario y retorna un token" do
      post '/auth', valid_user.to_json, "CONTENT_TYPE" => "application/json"
      expect(last_response.status).to eq(200)
      json = JSON.parse(last_response.body)
      expect(json).to have_key("token")
    end

    it "falla login con credenciales invalidas" do
      post '/auth', invalid_user.to_json, "CONTENT_TYPE" => "application/json"
      expect(last_response.status).to eq(404)
      json = JSON.parse(last_response.body)
      expect(json["error"]).to eq("Fallo iniciando sesión")
    end

    it "falla con JSON invalido" do
      post '/auth', "not a json", "CONTENT_TYPE" => "application/json"
      expect(last_response.status).to eq(500)
    end
  end
end