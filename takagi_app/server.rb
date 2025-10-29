require 'takagi'

class InteropTestServer < Takagi::Base
  # Basic GET endpoint for testing
  get '/temperature' do
    json temp: 22.5, unit: 'celsius'
  end
end

# Start server when run directly
if __FILE__ == $0
  port = ENV.fetch('COAP_PORT', 5683).to_i
  puts "Starting Takagi interop test server on port #{port}..."
  puts "Test endpoint: coap://localhost:#{port}/temperature"
  InteropTestServer.run!(port: port)
end