MinHTTP
=======

An HTTP library for the minimalist. It allows you to send and receive raw HTTP requests. It's a very thin wrapper around EventMachine's connect method with some SSL validation added. It uses http_parser.rb for very fast HTTP parsing.

Example:

    require 'minhttp'

    data = <<-HTTP
    GET / HTTP/1.0\r
    Host: www.yahoo.com\r

    HTTP

    EventMachine::run do
      MinHTTP.connect("www.yahoo.com", data) do |raw_response, parsed_response|
        puts "Received #{parsed_response.status_code} status from Google"
        puts "First 100 characters of raw HTTP response:"
        puts raw_response[0..100]
        EM::stop
      end
    end


Features:

    * Issue an exact HTTP request
    * See the exact HTTP response
    * See the parsed HTTP response
    * Validate the certificate of the server


Non-Features:

    * get() or post() helper methods (plenty of other HTTP libraries have these)


