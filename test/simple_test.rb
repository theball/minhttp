require 'minitest/autorun'
require_relative "../lib/minhttp"

class SimpleTest < MiniTest::Unit::TestCase
  def test_simple_google
    data = <<-HTTP
GET / HTTP/1.0\r
Host: www.google.com\r

HTTP

    EventMachine::run do
      Http::Min.connect("www.google.com", data) do |raw_response, parsed_response|
        assert(parsed_response.status_code == 200, "Response from google should be 200 but is #{parsed_response.status_code}")
        assert(raw_response.length > 0, "Raw response from google should be have size larger than 0")
        EM::stop
      end
    end

  end
end

