require 'openssl'
require 'base64'
require 'aspector'

class SimpleCipher
  attr_accessor :key
  ALGORITHM = 'AES-128-ECB'

  aspector do
    before :encrypt, :decrypt do
      if !@key
        raise "Error: No key has been set for this cipher."
      end
    end
  end
  
  def initialize key=nil
    @key = key
  end
  
  def encrypt_message msg
    begin
      cipher = OpenSSL::Cipher.new ALGORITHM
      cipher.encrypt()
      cipher.key = @key
      crypt = cipher.update(msg) + cipher.final()
      crypt_string = (Base64.encode64(crypt))
      return crypt_string
    rescue Exception => exc
      puts "Message for the encryption log file for message #{msg} = #{exc.message}"
    end
  end

  def decrypt_message msg
    begin
      cipher = OpenSSL::Cipher.new ALGORITHM
      cipher.decrypt()
      cipher.key = @key
      tempkey = Base64.decode64(msg)
      crypt = cipher.update tempkey
      crypt << cipher.final()
      return crypt
    rescue Exception => exc
      puts "Message for the decryption log file for message #{msg} = #{exc.message}"
    end
  end
end