require_relative '../utils.rb'
require 'digest/sha1'

class ClientProxy

  FILE_SERVER_NAME = 'Thor'

  def initialize username, password
    @file_server_socket = 
      TCPSocket.open(
        SERVICE_CONNECTION_DETAILS['file']['ip'],
        SERVICE_CONNECTION_DETAILS['file']['port'])

    @username = username
    @key = Digest::SHA1.hexdigest(password)
  end

  def authenticate
    LOGGER.log "//// Attempting authentication for #{@username} on #{FILE_SERVER_NAME} ////"
    @authentication_socket = 
      TCPSocket.open(
        SERVICE_CONNECTION_DETAILS['authentication']['ip'],
        SERVICE_CONNECTION_DETAILS['authentication']['port'])

    @authentication_socket.puts generate_authentication_request_message
    response = JSON.parse @authentication_socket.recv 10000

    if response['success']
      LOGGER.log "Authenticated #{@username} for #{FILE_SERVER_NAME}"
      @authentication_data = SimpleCipher.decrypt_message response['content'], @key
      @authentication_data = JSON.parse @authentication_data
      @authentication_data['session_timeout'] = Time.parse @authentication_data['session_timeout']
    else
      LOGGER.log "Authentication failed for #{@username} on #{FILE_SERVER_NAME}"
    end
  end

  def open file_path
    LOGGER.log "\n###### #{@username} is opening #{file_path} ######\n"
    message = { :action => 'open', :path => "#{file_path}" }
    securely_message_file_server message.to_json
    get_decrypted_file_server_response
  end

  def close
    LOGGER.log "\n###### #{@username} is closing his current file ######\n"
    message = { :action => 'close' }
    securely_message_file_server message.to_json
    get_decrypted_file_server_response
  end

  def read
    LOGGER.log "\n###### #{@username} is reading his current file ######\n"
    message = { :action => 'read' }
    securely_message_file_server message.to_json

    # Check if passable to read and get file size
    response = get_decrypted_file_server_response
    if response['status'] == 'OK'
      file_size = response['file_stream_size']

      # Tell FileServer we are ready to begin download
      message = { :status => 'OK' }
      securely_message_file_server message.to_json

      # Begin download
      file = download_and_decrypt_file file_size, @authentication_data['session_key'], @file_server_socket
      return file['file_content']
    else
      return response
    end
  end

  def write content
    LOGGER.log "\n###### #{@username} is writing to his current file ######\n"

    # Tell server that we want to upload how large the file will be.
    LOGGER.log 'Informing server of write intention and stream size'
    message = { :action => 'write',
                :file_stream_size =>
                    find_encrypted_file_stream_size(content, @authentication_data['session_key']) }
    securely_message_file_server message.to_json

    # Await response from server
    response = get_decrypted_file_server_response
    if response['status'] == 'OK'
      # Server is ready for the upload, bombs away!
      LOGGER.log 'Beginning to stream to server'
      message = { :file_content => content }
      @file_server_socket.write SimpleCipher.encrypt_message message.to_json, @authentication_data['session_key']

      LOGGER.log 'Awaiting download confirmation from server'
      return get_decrypted_file_server_response
    else
      return response
    end
  end

  def disconnect
    message = { :action => 'disconnect' }
    securely_message_file_server message.to_json
    @file_server_socket.close()
  end

  private

    def securely_message_file_server message
      maybe_update_authentication_session()

      message = {
        :ticket => @authentication_data['ticket'],
        :request => SimpleCipher.encrypt_message(message, @authentication_data['session_key'])
      }

      @file_server_socket.puts message.to_json
      LOGGER.log "#{@username} has just securely messaged the file server"
    end

    def get_decrypted_file_server_response
      response = read_socket_stream @file_server_socket
      JSON.parse SimpleCipher.decrypt_message response, @authentication_data['session_key']
    end

    def generate_authentication_request_message
      encrypted = {
        :LOGIN => {
          :SERVER => "#{FILE_SERVER_NAME}"
        }
      }
      encrypted = SimpleCipher.encrypt_message encrypted.to_json, @key

      message = {
        :USER_NAME => @username, 
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
