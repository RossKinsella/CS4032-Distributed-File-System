require '../utils.rb'

class AuthService

  USERNAME_KEYS = {
      "user-1" => Digest::SHA1.hexdigest("kittens123"),
      "Joe" => Digest::SHA1.hexdigest("puppies"),
      "John" => Digest::SHA1.hexdigest("xxx_lemon_pledge_xxx"),
      "Alex" => Digest::SHA1.hexdigest("42")
  }

  FILESERVER_KEYS = {
      "Thor" => Digest::SHA1.hexdigest("__Thor__password__")
  }

  AUTH_KEY = Digest::SHA1.hexdigest "admin123"

  SIX_HOURS_IN_SECONDS = 60 * 60 * 6

  def login client_socket, message
    LOGGER.log "Attempting authentication for #{message['USER_NAME']}"
    auth_results = authenticate message
    
    if auth_results['success']
      LOGGER.log "#{message['USER_NAME']} authentication successful"
      client_socket.puts generate_successful_authentication_message auth_results
      client_socket.close()
    else
      LOGGER.log "#{message['USER_NAME']} authentication failed"
      client_socket.puts generate_failed_authentication_message
      client_socket.close()
    end  
  end

  private

    # Checks if the message can be decrpyted by the key associated with a given
    # plain-text username.
    # Returns a hash of data needed to process a successful or failed login attempt.
    # return hash = {
    #  :success => true|false,
    #  :user_name => Optional,
    #  :user_key => Optional,
    #  :file_server => Optional
    # }
    def authenticate message
      results = {}

      user_name = message['USER_NAME']
      if USERNAME_KEYS[user_name]
        stored_key = USERNAME_KEYS[user_name]

        encrypted_request = message['REQUEST']
        decrypted_request = SimpleCipher.decrypt_message encrypted_request, stored_key
        decrypted_request =  JSON.parse decrypted_request

        if decrypted_request['LOGIN']
          results['success'] = true
          results['user_name'] = user_name
          results['user_key'] = stored_key
          results['file_server'] = decrypted_request['LOGIN']['SERVER']
        end
      end

      results
    end

    def generate_successful_authentication_message data
      session_key = generate_key().to_s

      encrypted = {
        :ticket => SimpleCipher.encrypt_message(session_key, FILESERVER_KEYS[data['file_server']]),
        :session_key => session_key,
        :session_timeout => Time.now + SIX_HOURS_IN_SECONDS,
        :server_id => data['file_server']
      }

      message = {
        :success => true,
        :content => SimpleCipher.encrypt_message(encrypted.to_json, data['user_key'])
      }
      message.to_json
    end

    def generate_failed_authentication_message
      message = {
        :content => 'The username and password did not match'
      }
      message.to_json
    end

end