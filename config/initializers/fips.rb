require 'digest'
require 'openssl'
require 'sprockets'
# override the default Digest with OpenSSL::Digest
Digest::SHA256 = OpenSSL::Digest::SHA256
Digest::SHA1 = OpenSSL::Digest::SHA1

OpenSSL.fips_mode = true
ActiveSupport::Digest.hash_digest_class = OpenSSL::Digest::SHA1.new
Sprockets::DigestUtils.module_eval do
  def digest_class
    OpenSSL::Digest::SHA256
  end
end

new_sprockets_config = {}
Sprockets.config.each do |key, val|
  new_sprockets_config[key] = val
end
new_sprockets_config[:digest_class] = OpenSSL::Digest::SHA256
Sprockets.config = new_sprockets_config.freeze