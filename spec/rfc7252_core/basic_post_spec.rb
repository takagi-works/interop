require 'spec_helper'

# CoAP Client Command:
# coap-client-gnutls -v 9 -m post coap://localhost:5683/data -e '{"value": 42}'

RSpec.describe "RFC 7252 - Basic POST Request" do

  CoAPClients.each do |client_name, client|
    context "using #{client_name}" do

      describe "POST /data" do
        it "returns 2.01 Created response code" do
          payload = '{"value": 42}'
          response = client.post('/data', payload)
          expect(response.code).to eq('2.01')
        end

        it "echoes back the posted data" do
          payload = '{"value": 42}'
          response = client.post('/data', payload)
          expect(response.payload).to include_json(received: '{"value": 42}')
        end

        it "returns JSON payload with creation confirmation" do
          payload = '{"value": 42}'
          response = client.post('/data', payload)
          expect(response.payload).to include_json(status: 'created', id: 123)
        end

        it "includes Content-Format option for JSON (50)" do
          payload = '{"value": 42}'
          response = client.post('/data', payload)
          expect(response.content_format).to eq("application/json")
        end

        it "returns successful status" do
          payload = '{"value": 42}'
          response = client.post('/data', payload)
          expect(response).to be_success
        end

        it "can parse JSON response" do
          payload = '{"value": 42}'
          response = client.post('/data', payload)
          json = response.json

          expect(json).to be_a(Hash)
          expect(json['status']).to eq('created')
          expect(json['id']).to eq(123)
        end
      end

    end
  end

end