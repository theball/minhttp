require 'http/parser'
require 'eventmachine'
require 'logger'
require_relative "ssl_validator"

#
# The minimal HTTP client
#   Sends a raw http request (bytes)
#   Parses the response and provides both the parsed and the raw response
#   Supports ssl
#
class MinHTTP < EventMachine::Connection

  attr_accessor :host, :ssl, :callback, :request_data

  def self.connections
    @@connections
  end
    
  def self.configure(options)
    @@options = options
    @@logger = options[:logger] || Logger.new(STDOUT)
    @@connections = 0
    Proxy::SSLValidator.configure
  end

  def self.connect(host, data, port=80, ssl=false, &callback)
    EventMachine.connect(host, port, self) do |c|
      # this code runs after 'post_init', before 'connection_completed'
      c.host = host
      c.ssl = ssl
      c.callback = callback
      c.request_data = data
    end
  end

  def post_init
    @@connections += 1
    @parser = Http::Parser.new
    @response_data = ""
  end

  def connection_completed
    start_tls(:verify_peer => true) if @ssl
    send_data @request_data
  end

  def receive_data(data)
    @response_data << data
    begin
      @parser << data
    rescue HTTP::Parser::Error => e
      @@logger.warn "Failed to parse: #{data}"
      raise e
    end
  end

  def unbind
    @@connections -= 1
    @callback.call(@response_data, @parser)
  end

  #
  # Called once per cert received
  # The certs aren't verified until the handshake is completed
  #
  def ssl_verify_peer(cert)
    @certs ||= []
    @certs << cert unless @certs.include?(cert)
    true
  end
  
  #
  # Verify the certs and throw an exception if they are not valid
  #
  def ssl_handshake_completed
    return unless @@options[:verify_ssl]
    close_connection unless Proxy::SSLValidator.validate(@certs, @host)
  end

end
