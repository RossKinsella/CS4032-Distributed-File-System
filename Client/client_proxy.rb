require '../utils.rb'
require 'digest/sha1'

class ClientProxy
  attr_accessor :server_socket

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
    securely_message_file_server "OPEN; PATH: #{file_path}"
    get_decrypted_file_server_response
  end

  def close
    LOGGER.log "\n###### #{@username} is closing his current file ######\n"
    securely_message_file_server 'CLOSE'
    get_decrypted_file_server_response
  end

  def read
    LOGGER.log "\n###### #{@username} is reading his current file ######\n"
    securely_message_file_server 'READ'

    # TODO: Encrypt response
    headers = @file_server_socket.gets()
    status = get_message_param headers, 'STATUS'
    if status == 'OK'
      return get_read_body headers, @file_server_socket
    else
      return 'Server Error.'
    end
  end

  def write content
    LOGGER.log "\n###### #{@username} is writing to his current file ######\n"
    headers = "WRITE; NUM_LINES:#{content.lines.count}"
    # securely_message_file_server headers << '\n' << content
    @file_server_socket.puts headers << '\n' << content
    get_decrypted_file_server_response
  end

  def disconnect
    @file_server_socket.puts 'DISCONNECT'
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
      response = @file_server_socket.recv 1000
      SimpleCipher.decrypt_message response, @authentication_data['session_key']
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
          raise "Authentication has failed. Please contact support."
        end
      end
    end

end
