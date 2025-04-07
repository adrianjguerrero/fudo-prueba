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

  describe "Endpoints de productos" do

    before(:each) do
      # nos autenticamos
      post '/auth', valid_user.to_json, "CONTENT_TYPE" => "application/json"
      @token = JSON.parse(last_response.body)["token"]
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
end