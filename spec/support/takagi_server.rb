require_relative '../../takagi_app/server'

module TakagiServerHelper
  @server_pid = nil
  @server_port = ENV.fetch('COAP_PORT', 5683).to_i

  def self.start_server
    return if @server_pid

    puts "\nStarting Takagi test server on port #{@server_port}..."

    @server_pid = fork do
      # Suppress server output during tests unless verbose
      unless ENV['VERBOSE']
        $stdout.reopen('/dev/null', 'w')
        $stderr.reopen('/dev/null', 'w')
      end

      begin
        InteropTestServer.run!(port: @server_port)
      rescue => e
        puts "Server error: #{e.message}" if ENV['VERBOSE']
        exit 1
      end
    end

    # Give server time to start
    sleep 2

    # Verify server is running
    unless server_running?
      stop_server
      raise "Failed to start Takagi server on port #{@server_port}"
    end

    puts "Takagi server started (PID: #{@server_pid})\n"
  end

  def self.stop_server
    return unless @server_pid

    puts "\nStopping Takagi test server..."

    begin
      # First, kill all child processes (Takagi workers)
      kill_process_tree(@server_pid)

      # Send TERM signal to main process
      Process.kill('TERM', @server_pid)

      # Wait up to 3 seconds for graceful shutdown
      timeout = 3
      start_time = Time.now

      loop do
        begin
          # Check if process is still alive
          Process.kill(0, @server_pid)

          # If we've waited too long, break and force kill
          if Time.now - start_time > timeout
            puts "Timeout waiting for server to stop, forcing kill..." if ENV['VERBOSE']
            break
          end

          sleep 0.1
        rescue Errno::ESRCH
          # Process has exited, reap it
          Process.wait(@server_pid) rescue Errno::ECHILD
          @server_pid = nil
          puts "Takagi server stopped\n"
          return
        end
      end

      # Force kill if still running after timeout
      begin
        Process.kill('KILL', @server_pid)
        Process.wait(@server_pid)
      rescue Errno::ESRCH, Errno::ECHILD
        # Already dead
      end
    rescue Errno::ESRCH, Errno::ECHILD
      # Process already gone
    ensure
      @server_pid = nil
      puts "Takagi server stopped\n"
    end
  end

  def self.kill_process_tree(pid)
    # Get all child PIDs
    children = `pgrep -P #{pid} 2>/dev/null`.split.map(&:to_i)

    # Recursively kill children first
    children.each do |child_pid|
      begin
        kill_process_tree(child_pid)
        Process.kill('TERM', child_pid)
      rescue Errno::ESRCH
        # Already dead
      end
    end
  rescue => e
    # Ignore errors in finding children
  end

  def self.server_running?
    # Check if port is in use
    output = `lsof -i :#{@server_port} 2>/dev/null`
    !output.empty?
  end

  def self.server_pid
    @server_pid
  end
end