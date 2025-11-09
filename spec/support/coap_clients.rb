require 'json'

# Response object that all clients return
class Response
  attr_reader :code, :payload, :content_format, :raw_output

  def initialize(code:, payload:, content_format: nil, raw_output: '')
    @code = code
    @payload = payload
    @content_format = content_format
    @raw_output = raw_output
  end

  def json
    return nil if payload.nil? || payload.empty?
    JSON.parse(payload)
  rescue JSON::ParserError
    nil
  end

  def success?
    code && code.start_with?('2.')
  end

  def client_error?
    code && code.start_with?('4.')
  end

  def server_error?
    code && code.start_with?('5.')
  end
end

# LibCoAP client wrapper
class LibCoAPClient
  def get(path, options = {})
    cmd = "coap-client-gnutls -v 9 -m get coap://#{server_address}#{path}"
    puts "Executing: #{cmd}" if ENV['VERBOSE']

    output = execute_command(cmd)
    parse_output(output)
  end

  def post(path, payload, options = {})
    cmd = "coap-client-gnutls -v 9 -m post coap://#{server_address}#{path} -e '#{payload}'"
    puts "Executing: #{cmd}" if ENV['VERBOSE']

    output = execute_command(cmd)
    parse_output(output)
  end

  def put(path, payload, options = {})
    cmd = "coap-client-gnutls -v 9 -m put coap://#{server_address}#{path} -e '#{payload}'"
    output = execute_command(cmd)
    parse_output(output)
  end

  def delete(path, options = {})
    cmd = "coap-client-gnutls -v 9 -m delete coap://#{server_address}#{path}"
    output = execute_command(cmd)
    parse_output(output)
  end

  def observe(path, duration: 5)
    cmd = "timeout #{duration}s coap-client-gnutls -v 9 -m get coap://#{server_address}#{path} -s #{duration} -O 6,0"
    output = execute_command(cmd)
    parse_observe_output(output)
  end

  def self.available?
    system('which coap-client-gnutls > /dev/null 2>&1')
  end

  private

  def execute_command(cmd)
    output = `#{cmd} 2>&1`
    puts "Output: #{output}" if ENV['VERBOSE']
    output
  end

  def parse_output(output)
    # libcoap format with -v 9 verbosity:
    # Debug lines followed by response line like:
    # UDP: v:1 t:ACK c:2.05 i:xxxx {token} [ options ] :: payload
    # TCP: v:Reliable c:2.01 {token} [ options ] :: payload

    # Find the response line - try UDP format first, then TCP format
    response_line = output.lines.find { |line| line =~ /v:1.*t:(ACK|CON).*c:\d\.\d+/ }

    # Try TCP/Reliable format
    response_line ||= output.lines.find { |line| line =~ /v:Reliable.*c:\d\.\d+/ }

    # If no response line found, try finding any line with just the code (fallback)
    response_line ||= output.lines.find { |line| line =~ /c:(\d\.\d+)/ }

    if response_line
      # Extract response code (c:2.05)
      code = response_line[/c:(\d\.\d+)/, 1]

      # Extract payload - try multiple patterns
      payload = if response_line =~ /:: (.+)$/m
        # Everything after ::
        $1.strip
      elsif response_line =~ /\} :: (.+)$/m
        # After closing brace and ::
        $1.strip
      else
        # Look for JSON in the output (fallback)
        json_match = output[/(\{.+\})/m]
        json_match&.strip
      end

      # Remove surrounding single or double quotes from payload
      payload = payload.gsub(/^['"]|['"]$/, '') if payload

      # Extract Content-Format option from anywhere in output
      content_format = output[/Content-Format:([a-z]+\/[a-z]+|\d+)/, 1]

      Response.new(
        code: code,
        payload: payload,
        content_format: content_format,
        raw_output: output
      )
    else
      # No response line found - return empty response
      Response.new(
        code: nil,
        payload: nil,
        content_format: nil,
        raw_output: output
      )
    end
  end

  def parse_observe_output(output)
    # Each notification is on a separate line starting with v:1
    output.lines.map do |line|
      parse_output(line) if line.include?('v:1')
    end.compact
  end

  def server_address
    "localhost:#{ENV.fetch('COAP_PORT', 5683)}"
  end
end

class LibCoAPTcpClient < LibCoAPClient
  def get(path, options = {})
    cmd = "coap-client-gnutls -v 9 -m get coap+tcp://#{server_address}#{path}"
    puts "Executing: #{cmd}" if ENV['VERBOSE']

    output = execute_command(cmd)
    parse_output(output)
  end

  def post(path, payload, options = {})
    cmd = "coap-client-gnutls -v 9 -m post coap+tcp://#{server_address}#{path} -e '#{payload}'"
    puts "Executing: #{cmd}" if ENV['VERBOSE']

    output = execute_command(cmd)
    parse_output(output)
  end

  def put(path, payload, options = {})
    cmd = "coap-client-gnutls -v 9 -m put coap+tcp://#{server_address}#{path} -e '#{payload}'"
    output = execute_command(cmd)
    parse_output(output)
  end

  def delete(path, options = {})
    cmd = "coap-client-gnutls -v 9 -m delete coap+tcp://#{server_address}#{path}"
    output = execute_command(cmd)
    parse_output(output)
  end

  def observe(path, duration: 5)
    cmd = "timeout #{duration}s coap-client-gnutls -v 9 -m get coap+tcp://#{server_address}#{path} -s #{duration} -O 6,0"
    output = execute_command(cmd)
    parse_observe_output(output)
  end
end

# Registry of available UDP clients
module CoAPClients
  CLIENTS = {
    'libcoap' => LibCoAPClient.new
  }

  def self.each(&block)
    # Filter by environment variable if set
    active_clients = ENV['COAP_CLIENTS']&.split(',') || CLIENTS.keys

    active_clients.each do |name|
      next unless CLIENTS[name]
      block.call(name, CLIENTS[name])
    end
  end

  def self.[](name)
    CLIENTS[name]
  end
end

# Registry of available TCP clients
module CoAPTcpClients
  CLIENTS = {
    'libcoap' => LibCoAPTcpClient.new
  }

  def self.each(&block)
    # Filter by environment variable if set
    active_clients = ENV['COAP_CLIENTS']&.split(',') || CLIENTS.keys

    active_clients.each do |name|
      next unless CLIENTS[name]
      block.call(name, CLIENTS[name])
    end
  end

  def self.[](name)
    CLIENTS[name]
  end
end