require_relative 'lib/min_http'

data = <<-HTTP
GET / HTTP/1.0\r
Host: www.google.com\r

HTTP

EventMachine::run do
  Http::Min.connect("www.google.com", data) do |raw_response, parsed_response|
    puts "Received #{parsed_response.status_code} status from Google"
    puts "First 100 characters of raw HTTP response:"
    puts raw_response[0..100]
    EM::stop
  end
end
