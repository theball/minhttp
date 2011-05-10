require 'openssl'
require 'logger'

module Http
  class SSLValidator
    class << self

      def configure(logger)
        @@logger = logger || Logger.new(STDOUT)
        create_store
      end

      def configured?
        class_variable_defined?("@@logger")
      end

      #
      # Completes the 3 steps to certificate chain verification
      # Also applies if there is just one cert in the chain, but the last
      # step won't run
      #
      def validate(certs, host)
        certs = certs.collect { |c| OpenSSL::X509::Certificate.new(c) }
        @@logger.debug("Verifying certs for #{host}")
        
        # 1. Verify that the last cert has a valid hostname 
        unless OpenSSL::SSL.verify_certificate_identity(certs.last, host)
          @@logger.error("Hostname #{host} does not match cert: #{certs.last}")
          return false
        end
                
        # 2. Verify that the first cert can be validated by a root certificate
        unless @@store.verify(certs.first)
          @@logger.error("Cert not validated by any of the root certificates in my store: #{certs.first}")
          return false
        end
        
        # 3. Verify that every cert in the chain is validated by the cert after it
        (certs.length - 1).times do |i|
          cert_a = certs[i+1]
          cert_b = certs[i]
          unless cert_a.verify(cert_b.public_key)
            @@logger.error("Broken link in certificate chain for #{host} between #{cert_a} and #{cert_b}")
            return false
          end
        end
        true
      end


      private

      #
      # Create a Ruby OpenSSL certificate store with all the certs
      # in the given root certificate file. Ruby doesn't supply a clean
      # way to get the root certs out of a root cert file so I have to split
      # it manually.
      #
      def create_store
        configure unless configured?

        # Root certs downloaded from: http://curl.haxx.se/ca/cacert.pem
        ca_file_path = File.join(File.dirname(__FILE__), "../cacert.pem")

        @@store = OpenSSL::X509::Store.new
        splitter = "END CERTIFICATE-----"
        File.read(ca_file_path).strip.split(splitter).each do |c|
          begin
            c << splitter
            @@store.add_cert OpenSSL::X509::Certificate.new(c)
          rescue OpenSSL::X509::CertificateError
            @@logger.warn "Error loading cert from #{c} from #{ca_file_path}"
          end
        end
        @@store
      end

    end
  end
end
