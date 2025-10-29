# Example spec_helper.rb for Takagi CoAP Interoperability Tests
# Copy this to spec/spec_helper.rb in your repository

require 'rspec'
require 'json'

# Load support files
Dir[File.join(__dir__, 'support', '**', '*.rb')].each { |f| require f }

RSpec.configure do |config|
  # Use new syntax (expect instead of should)
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Shared context and metadata
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true

  # Output
  config.default_formatter = 'doc' if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed

  # Start/stop Takagi server before/after entire test suite
  config.before(:suite) do
    puts "\n=== Starting Takagi CoAP Server ==="
    start_takagi_server
    sleep 2  # Give server time to start
    verify_server_running
    puts "=== Server Ready ==="
  end

  config.after(:suite) do
    puts "\n=== Stopping Takagi CoAP Server ==="
    stop_takagi_server
    puts "=== Server Stopped ==="
  end

  # Print which clients are available
  config.before(:suite) do
    puts "\n=== Available CoAP Clients ==="
    CoAPClients.available.each do |client_name|
      puts "  ✓ #{client_name}"
    end
    puts "=========================\n\n"
  end
end

# Helper methods for starting/stopping server
def start_takagi_server
  port = ENV.fetch('COAP_PORT', 5683).to_i

  # Start server in background
  @server_pid = Process.spawn(
    'ruby', 'takagi_app/server.rb',
    out: 'tmp/server.log',
    err: 'tmp/server.log'
  )

  Process.detach(@server_pid)
end

def stop_takagi_server
  return unless @server_pid

  begin
    Process.kill('TERM', @server_pid)
    Process.wait(@server_pid, Process::WNOHANG)
  rescue Errno::ESRCH, Errno::ECHILD
    # Process already gone
  end
end

def verify_server_running
  port = ENV.fetch('COAP_PORT', 5683).to_i
  max_attempts = 10

  max_attempts.times do |i|
    # Try to connect with coap-client
    result = `coap-client -m get coap://localhost:#{port}/ping 2>&1`
    return if $?.success? && result.include?('Pong')

    sleep 0.5
  end

  raise "Takagi server failed to start on port #{port}"
end

# Custom matchers
RSpec::Matchers.define :include_json do |expected|
  match do |actual|
    payload = actual.is_a?(String) ? actual : actual.to_s
    json = JSON.parse(payload) rescue nil
    return false unless json

    expected.all? { |key, value| json[key.to_s] == value }
  end

  failure_message do |actual|
    "expected #{actual} to include JSON with #{expected}"
  end
end

RSpec::Matchers.define :be_success do
  match do |response|
    response.code&.start_with?('2.')
  end

  failure_message do |response|
    "expected response code #{response.code} to be success (2.xx)"
  end
end

RSpec::Matchers.define :be_client_error do
  match do |response|
    response.code&.start_with?('4.')
  end

  failure_message do |response|
    "expected response code #{response.code} to be client error (4.xx)"
  end
end

RSpec::Matchers.define :be_server_error do
  match do |response|
    response.code&.start_with?('5.')
  end

  failure_message do |response|
    "expected response code #{response.code} to be server error (5.xx)"
  end
end
