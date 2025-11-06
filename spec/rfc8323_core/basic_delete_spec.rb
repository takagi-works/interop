require 'spec_helper'

# CoAP Client Command:
# coap-client-gnutls -v 9 -m delete coap+tcp://localhost:5683/resource/456

RSpec.describe "RFC 8323 - Basic DELETE Request" do

  CoAPTcpClients.each do |client_name, client|
    context "using #{client_name}" do

      describe "DELETE /resource/:id" do
        it "returns 2.02 Deleted response code" do
          response = client.delete('/resource/456')
          expect(response.code).to eq('2.02')
        end

        it "returns JSON payload with deletion confirmation" do
          response = client.delete('/resource/456')
          expect(response.payload).to include_json(status: 'deleted')
        end

        it "includes the deleted resource ID in response" do
          response = client.delete('/resource/456')
          expect(response.payload).to include_json(id: '456')
        end

        it "includes Content-Format option for JSON (50)" do
          response = client.delete('/resource/456')
          expect(response.content_format).to eq("application/json")
        end

        it "returns successful status" do
          response = client.delete('/resource/456')
          expect(response).to be_success
        end

        it "can parse JSON response" do
          response = client.delete('/resource/456')
          json = response.json

          expect(json).to be_a(Hash)
          expect(json['status']).to eq('deleted')
          expect(json['id']).to eq('456')
        end
      end

    end
  end

end