version = File.read("VERSION").strip

Gem::Specification.new do |s|
  s.name        = "minhttp"
  s.version     = version
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Andrew Farmer"]
  s.email       = ["ahfarmer@gmail.com"]
  s.homepage    = "http://github.com/ahfarmer/minhttp"
  s.summary     = %q{An HTTP library for the minimalist.}
  s.description = %q{MinHTTP allows one to send and receive raw HTTP requests. It's a very thin wrapper around EventMachine's connect method with some SSL validation added.}

  s.rubyforge_project = "minhttp"

  s.files         = Dir['README.md', 'VERSION', 'Gemfile', 'Rakefile', 'cacert.pem', 'examples/*', 'lib/*']
  s.test_files    = Dir['test/*']
  s.require_path  = "lib"

  s.add_dependency "http_parser.rb"
  s.add_dependency "eventmachine"

end
