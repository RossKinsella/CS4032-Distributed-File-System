require_relative '../Common/utils'

class ClientSession

  attr_accessor :service_socket, :service_ip, :service_port, :client_username, :client_key, :authentication_data

  def initialize service_ip, service_port, client_username, client_key
    @service_socket = TCPSocket.open service_ip, service_port
    @service_ip = service_ip # If you ask the socket for ip/port you may get unexpected results.
    @service_port = service_port
    @client_username = client_username
    @client_key = client_key
    authenticate
  end

  def securely_message_service message
    maybe_update_authentication_session()

    message = {
      :ticket => @authentication_data['ticket'],
      :request => SimpleCipher.encrypt_message(message, @authentication_data['session_key'])
    }

    message = message.to_json
    @service_socket.puts message
    LOGGER.log "#{@client_username} has just securely messaged #{service_ip}:#{service_port}: #{message.truncate(180)}"
  end

  def get_decrypted_service_response
    LOGGER.log "#{@client_username} is waiting for a response from #{service_ip}:#{service_port}"
    response = read_socket_stream @service_socket
    decrypted_response = SimpleCipher.decrypt_message response, @authentication_data['session_key']
    
    LOGGER.log "#{@client_username} has gotten a response from #{service_ip}:#{service_port}: #{decrypted_response.truncate(180)}"
    JSON.parse decrypted_response
  end

  def end
    message = { :action => 'disconnect' }
    securely_message_service message.to_json
    @service_socket.close()
    @service_socket = nil
  end

  private

    def authenticate
      LOGGER.log "//// Attempting authentication for #{ @client_username } on #{@service_ip + ':' + @service_port} ////"
      @authentication_socket = 
        TCPSocket.open(
          SERVICE_CONNECTION_DETAILS['authentication']['ip'],
          SERVICE_CONNECTION_DETAILS['authentication']['port'])

      auth_request = generate_authentication_request_message
      @authentication_socket.puts auth_request
      LOGGER.log "#{client_username} has just sent #{SERVICE_CONNECTION_DETAILS['authentication']['ip']+ ':' + SERVICE_CONNECTION_DETAILS['authentication']['port']} an auth request: #{auth_request}"
      response = JSON.parse @authentication_socket.recv 10000
      LOGGER.log "#{client_username} has gotten a message from #{SERVICE_CONNECTION_DETAILS['authentication']['ip']+ ':' + SERVICE_CONNECTION_DETAILS['authentication']['port']}: #{response}"
      if response['success']
        LOGGER.log "Authenticated #{ client_username } on #{@service_ip + ':' + @service_port}"
        @authentication_data = SimpleCipher.decrypt_message response['content'], @client_key
        @authentication_data = JSON.parse @authentication_data
        @authentication_data['session_timeout'] = Time.parse @authentication_data['session_timeout']
      else
        raise response['content']
      end

      @authentication_socket.close
    end

    def generate_authentication_request_message
      encrypted = {
        :LOGIN => {
          :SERVER => "#{@service_ip + ':' + @service_port}"
        }
      }
      encrypted = SimpleCipher.encrypt_message encrypted.to_json, @client_key

      message = {
        :USER_NAME => @client_username, 
          :REQUEST => encrypted
      }

      message.to_json
    end

    def maybe_update_authentication_session
      if @authentication_data and @authentication_data['session_timeout'] > Time.now
        return
      else
        authenticate()
        if @authentication_data['session_timeout'] < Time.now
          raise 'Authentication has failed. Please contact support.'
        end
      end
    end

end
