require 'digest'
require 'openssl'
# override the default Digest with OpenSSL::Digest
Digest = OpenSSL::Digest
OpenSSL.fips_mode = true
ActiveSupport::Digest.hash_digest_class = OpenSSL::Digest::SHA1.new
Sprockets::DigestUtils.module_eval do
  def digest_class
    OpenSSL::Digest::SHA256
  end
end
