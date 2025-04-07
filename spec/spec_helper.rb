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

  describe "Pruebas de auth" do
    it "logea usuario y retorna un token" do
      post '/auth', valid_user.to_json, "CONTENT_TYPE" => "application/json"
      expect(last_response.status).to eq(200)
      json = JSON.parse(last_response.body)
      expect(json).to have_key("access_token")
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

    it "refresca el token" do
      post '/auth', valid_user.to_json, "CONTENT_TYPE" => "application/json"
      expect(last_response.status).to eq(200)
      refresh_token = JSON.parse(last_response.body)["refresh_token"]
      post '/refresh_token', { refresh_token: refresh_token }.to_json, "CONTENT_TYPE" => "application/json"
      json = JSON.parse(last_response.body)
      expect(last_response.status).to eq(200)
      expect(json).to have_key("access_token")
    end
  end

  describe "Endpoints de productos" do

    before(:each) do
      # nos autenticamos
      post '/auth', valid_user.to_json, "CONTENT_TYPE" => "application/json"
      @token = JSON.parse(last_response.body)["access_token"]
    end

    def create_product(name = "leche")
      post '/create_product', { name: name }.to_json, headers
      expect(last_response.status).to eq(202)
      JSON.parse(last_response.body)
    end

    def get_queue_info(queue_id)
      get "/queue_info/#{queue_id}", {}, headers
      JSON.parse(last_response.body)
    end
  
    let(:headers) do
      { "CONTENT_TYPE" => "application/json", "HTTP_AUTHORIZATION" => "#{@token}" }
    end

    it "falla en creación de producto si no hace login" do
      post '/create_product', { name: "leche" }.to_json, "CONTENT_TYPE" => "application/json"
      expect(last_response.status).to eq(401)
    end

    it "se encola la creación de un producto" do
      json = create_product('leche')
      expect(json).to have_key("queue_id")
    end

    it "se consulta estado de cola" do
      queue_id = create_product('leche')['queue_id']
      json = get_queue_info(queue_id)
      expect(json).to have_key("status_queue")
    end

    it "se consulta estado de cola teniendo producto" do
      queue_id = create_product('leche')['queue_id']
      sleep 6
      json = get_queue_info(queue_id)
      expect(json).to have_key("product")
    end

    it "se consulta producto de cola teniendo producto" do
      queue_id = create_product('leche')['queue_id']
      sleep 6
      product_id = get_queue_info(queue_id)['product']['id']
      get '/product/'+product_id, {}, headers
      json = JSON.parse(last_response.body)
      expect(json).to have_key("product")
    end
  end

  describe "pruebas de archivos" do
    it "retorna el archivo AUTHORS con cache de 24 hs" do
      get '/AUTHORS'
      expect(last_response.status).to eq(200)
      expect(last_response.body.strip).to eq("Adrian Guerrero")
      expect(last_response.headers["Cache-Control"]).to include("max-age=#{24 * 3600}")
    end

    it "retorna openapi.yaml sin cache" do
      get '/openapi.yaml'
      expect(last_response.status).to eq(200)
      expect(last_response.headers["Cache-Control"]).to include("no-store")
    end
  end
end