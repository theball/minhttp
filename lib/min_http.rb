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

  def self.configure(options={})
    @@options = options
    @@logger = options[:logger] || Logger.new(STDOUT)
    @@connections = 0
  end

  def self.configured?
    class_variable_defined?("@@logger")
  end

  def self.connect(host, data, port=80, ssl=false, &callback)
    configure unless configured?

    EventMachine.connect(host, port, self) do |c|
      # this code runs after 'post_init', before 'connection_completed'
      c.host = host
      c.ssl = ssl
      c.callback = callback
      c.request_data = data
    end
  end

  def post_init
    begin
      @@connections += 1
      @parser = Http::Parser.new
      @response_data = ""
    rescue Exception => e
      @@logger.error("Error in post_init: #{e}")
      raise e
    end
  end

  def connection_completed
    begin
      start_tls(:verify_peer => true) if @ssl
      send_data @request_data
    rescue Exception => e
      puts "Error in connection_completed: #{e}"
    end
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
    begin
      @@connections -= 1
      @callback.call(@response_data, @parser)
    rescue Exception => e
      @@logger.error("Error in unbind: #{e}")
      raise e
    end
  end

  #
  # Called once per cert received
  # The certs aren't verified until the handshake is completed
  #
  def ssl_verify_peer(cert)
    begin
      @certs ||= []
      @certs << cert unless @certs.include?(cert)
      true
    rescue Exception => e
      @@logger.error("Error in ssl_verify_peer: #{e}")
      raise e
    end
  end
  
  #
  # Verify the certs and throw an exception if they are not valid
  #
  def ssl_handshake_completed
    begin
      return unless @@options[:verify_ssl]
      close_connection unless Proxy::SSLValidator.validate(@certs, @host)
    rescue Exception => e
      @@logger.error("Error in ssl_handshake_completed: #{e}")
      raise e
    end
  end

end
