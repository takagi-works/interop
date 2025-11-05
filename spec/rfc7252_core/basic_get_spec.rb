require 'spec_helper'

# CoAP Client Command:
# coap-client-gnutls -v 9 -m get coap://localhost:5683/temperature

RSpec.describe "RFC 7252 - Basic GET Request" do

  CoAPClients.each do |client_name, client|
    context "using #{client_name}" do

      describe "GET /temperature" do
        it "returns 2.05 Content response code" do
          response = client.get('/temperature')
          expect(response.code).to eq('2.05')
        end

        it "returns JSON payload with temperature data" do
          response = client.get('/temperature')
          expect(response.payload).to include_json(temp: 22.5, unit: 'celsius')
        end

        it "includes Content-Format option for JSON (50)" do
          response = client.get('/temperature')
          expect(response.content_format).to eq("application/json")
        end

        it "returns successful status" do
          response = client.get('/temperature')
          expect(response).to be_success
        end

        it "can parse JSON response" do
          response = client.get('/temperature')
          json = response.json

          expect(json).to be_a(Hash)
          expect(json['temp']).to eq(22.5)
          expect(json['unit']).to eq('celsius')
        end
      end

    end
  end

end