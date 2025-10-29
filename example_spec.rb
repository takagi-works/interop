# Example Test File - Basic GET Request
# This demonstrates the structure of interoperability tests
# Copy to spec/rfc7252_core/basic_get_spec.rb in your repository

require 'spec_helper'

RSpec.describe "RFC 7252 - Basic GET Request", rfc: '7252' do

  # This iterates through ALL available CoAP clients
  # Each client will run all tests in this context
  CoAPClients.each do |client_name, client|
    context "using #{client_name}" do

      describe "GET /temperature" do
        it "returns 2.05 Content response" do
          response = client.get('/temperature')

          expect(response.code).to eq('2.05')
        end

        it "returns JSON payload with temperature data" do
          response = client.get('/temperature')

          expect(response.payload).to include_json(
            temp: 22.5,
            unit: 'celsius'
          )
        end

        it "includes Content-Format option for JSON" do
          response = client.get('/temperature')

          # Content-Format: 50 = application/json
          expect(response.content_format).to eq(50)
        end

        it "uses CON (Confirmable) message type by default" do
          response = client.get('/temperature')

          expect(response.message_type).to eq('CON')
        end
      end

      describe "GET /not-found" do
        it "returns 4.04 Not Found for non-existent resource" do
          response = client.get('/not-found')

          expect(response.code).to eq('4.04')
        end

        it "is a client error response" do
          response = client.get('/not-found')

          expect(response).to be_client_error
        end
      end

      describe "GET with Uri-Path segments" do
        it "handles multiple path segments" do
          response = client.get('/sensors/temp/room1')

          expect(response.code).to eq('2.05')
          expect(response.payload).to include_json(
            type: 'temp',
            room: 'room1'
          )
        end

        it "handles different room IDs" do
          response = client.get('/sensors/temp/room2')

          expect(response.code).to eq('2.05')
          expect(response.payload).to include_json(room: 'room2')
        end
      end

      describe "GET with query parameters" do
        it "handles Uri-Query option" do
          response = client.get('/search?filter=temperature&limit=10')

          expect(response.code).to eq('2.05')

          # Parse JSON response
          data = JSON.parse(response.payload)
          expect(data['query']).to include('filter' => 'temperature')
          expect(data['query']).to include('limit' => '10')
        end
      end

      describe "error handling" do
        it "returns 5.00 for server errors" do
          response = client.get('/error')

          expect(response).to be_server_error
          expect(response.code).to eq('5.00')
        end

        it "returns 4.03 for forbidden resources" do
          response = client.get('/forbidden')

          expect(response.code).to eq('4.03')
        end
      end

    end
  end

  # Additional tests can go here that don't need to run against all clients
  describe "client availability" do
    it "has at least one CoAP client available" do
      expect(CoAPClients.available.count).to be >= 1
    end
  end

end
