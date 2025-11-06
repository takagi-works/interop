require 'spec_helper'

# CoAP Client Command:
# coap-client-gnutls -v 9 -m put coap+tcp://localhost:5683/settings -e '{"brightness": 80}'

RSpec.describe "RFC 8323 - Basic PUT Request" do

  CoAPTcpClients.each do |client_name, client|
    context "using #{client_name}" do

      describe "PUT /settings" do
        it "returns 2.04 Changed response code" do
          payload = '{"brightness": 80}'
          response = client.put('/settings', payload)
          expect(response.code).to eq('2.04')
        end

        it "echoes back the updated data" do
          payload = '{"brightness": 80}'
          response = client.put('/settings', payload)
          expect(response.payload).to include_json(received: '{"brightness": 80}')
        end

        it "returns JSON payload with update confirmation" do
          payload = '{"brightness": 80}'
          response = client.put('/settings', payload)
          expect(response.payload).to include_json(status: 'updated')
        end

        it "includes Content-Format option for JSON (50)" do
          payload = '{"brightness": 80}'
          response = client.put('/settings', payload)
          expect(response.content_format).to eq("application/json")
        end

        it "returns successful status" do
          payload = '{"brightness": 80}'
          response = client.put('/settings', payload)
          expect(response).to be_success
        end

        it "can parse JSON response" do
          payload = '{"brightness": 80}'
          response = client.put('/settings', payload)
          json = response.json

          expect(json).to be_a(Hash)
          expect(json['status']).to eq('updated')
        end
      end

    end
  end

end