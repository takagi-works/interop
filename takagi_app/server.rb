require 'takagi'

class InteropTestServer < Takagi::Base
  # Basic GET endpoint for testing
  get '/temperature' do
    json temp: 22.5, unit: 'celsius'
  end

  # POST endpoint for creating resources
  post '/data' do
    received = request.payload
    created status: 'created', received: received, id: 123
  end

  # PUT endpoint for updating resources
  put '/settings' do
    received = request.payload
    changed status: 'updated', received: received
  end

  # DELETE endpoint for removing resources
  delete '/resource/:id' do
    id = params[:id]
    deleted status: 'deleted', id: id
  end
end

# Start server when run directly
if __FILE__ == $0
  port = ENV.fetch('COAP_PORT', 5683).to_i
  puts "Starting Takagi interop test server on port #{port}..."
  puts "Test endpoint: coap://localhost:#{port}/temperature"
  InteropTestServer.run!(port: port)
end