require 'rspec'
require 'json'
require_relative 'support/coap_clients'
require_relative 'support/takagi_server'

# Ensure server is stopped on exit, even if tests are interrupted
at_exit do
  TakagiServerHelper.stop_server
end

# Handle Ctrl+C gracefully
Signal.trap('INT') do
  puts "\n\nInterrupted! Cleaning up..."
  TakagiServerHelper.stop_server
  exit 1
end

Signal.trap('TERM') do
  puts "\n\nTerminated! Cleaning up..."
  TakagiServerHelper.stop_server
  exit 1
end

RSpec.configure do |config|
  # Start server before all tests
  config.before(:suite) do
    TakagiServerHelper.start_server
  end

  # Stop server after all tests
  config.after(:suite) do
    TakagiServerHelper.stop_server
  end

  # Better failure output
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # Mocking
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Shared context
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Output format
  if ENV['VERBOSE']
    config.formatter = :documentation
  end

  # Filter what runs
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  # Random order
  config.order = :random
  Kernel.srand config.seed
end

# Custom matcher for JSON responses
RSpec::Matchers.define :include_json do |expected|
  match do |actual|
    begin
      json = JSON.parse(actual)
      expected.all? { |key, value| json[key.to_s] == value }
    rescue JSON::ParserError
      false
    end
  end

  failure_message do |actual|
    "expected #{actual} to include JSON #{expected}"
  end
end