require '../common/utils.rb'

class AuthService

  USERNAME_KEYS = {
      "user-1" => Digest::SHA1.hexdigest("kittens123"),
      "Joe" => Digest::SHA1.hexdigest("puppies"),
      "John" => Digest::SHA1.hexdigest("xxx_lemon_pledge_xxx"),
      "Alex" => Digest::SHA1.hexdigest("42")
  }

  @@service_keys = {
      "#{get_service_id SERVICE_CONNECTION_DETAILS['file_servers'][0]}" => Digest::SHA1.hexdigest('bubbles'),
      "#{get_service_id SERVICE_CONNECTION_DETAILS['file_servers'][1]}" => Digest::SHA1.hexdigest('panda'),
      "#{get_service_id SERVICE_CONNECTION_DETAILS['file_servers'][2]}" => Digest::SHA1.hexdigest('kitten'),
      "#{get_service_id SERVICE_CONNECTION_DETAILS['directory']}" => Digest::SHA1.hexdigest('LEMONS'),
  }

  AUTH_KEY = Digest::SHA1.hexdigest "admin123"

  SIX_HOURS_IN_SECONDS = 60 * 60 * 6

  def login client_socket, message
    LOGGER.log "Attempting authentication for #{message['USER_NAME']}"
    auth_results = authenticate message
    
    if auth_results['success']
      LOGGER.log "#{message['USER_NAME']} authentication successful"
      client_socket.puts generate_successful_authentication_message auth_results
    else
      LOGGER.log "#{message['USER_NAME']} authentication failed"
      client_socket.puts generate_failed_authentication_message
    end
  end

  def self.service_keys
    @@service_keys
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

      begin
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
          results['service'] = decrypted_request['LOGIN']['SERVER']
        end
      end
      rescue
        results['success'] = false
      end
      results
    end

    def generate_successful_authentication_message data
      session_key = generate_key().to_s

      encrypted = {
        :ticket => SimpleCipher.encrypt_message(session_key, @@service_keys[data['service']]),
        :session_key => session_key,
        :session_timeout => Time.now + SIX_HOURS_IN_SECONDS,
        :server_id => data['service']
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
