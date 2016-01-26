require 'openssl'
require 'base64'

class SimpleCipher
  ALGORITHM = 'AES-128-ECB'
  
  def self.encrypt_message msg, key
    begin
      cipher = OpenSSL::Cipher.new ALGORITHM
      cipher.encrypt()
      cipher.key = key
      crypt = cipher.update(msg) + cipher.final()
      crypt_string = (Base64.encode64(crypt))
      return crypt_string
    rescue Exception => exc
      puts "Message for the encryption log file for message #{msg} = #{exc.message}"
    end
  end

  def self.decrypt_message msg, key
    begin
      cipher = OpenSSL::Cipher.new ALGORITHM
      cipher.decrypt()
      cipher.key = key
      tempkey = Base64.decode64(msg)
      crypt = cipher.update tempkey
      crypt << cipher.final()
      return crypt
    rescue Exception => exc
      puts "Message for the decryption log file for message #{msg} = #{exc.message}"
    end
  end
end