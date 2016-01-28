require_relative '../common/utils.rb'
require 'digest/sha1'

class ClientProxy

  FILE_SERVER_NAME = 'Thor'

  def initialize username, password
    @file_service_session = ClientSession.new(
        SERVICE_CONNECTION_DETAILS['file']['ip'],
        SERVICE_CONNECTION_DETAILS['file']['port'],
        username,
        Digest::SHA1.hexdigest(password) )

    @username = username
    @key = Digest::SHA1.hexdigest(password)
  end

  def open file_path
    LOGGER.log "\n###### #{@username} is opening #{file_path} ######\n"
    message = { :action => 'open', :path => "#{file_path}" }
    begin
      @file_service_session.securely_message_service message.to_json
    rescue => e
      return e
    end
    @file_service_session.get_decrypted_service_response
  end

  def close
    LOGGER.log "\n###### #{@username} is closing his current file ######\n"
    message = { :action => 'close' }
    begin
      @file_service_session.securely_message_service message.to_json
    rescue => e
      return e
    end
    @file_service_session.get_decrypted_service_response
  end

  def read
    LOGGER.log "\n###### #{@username} is reading his current file ######\n"
    message = { :action => 'read' }
    begin
      @file_service_session.securely_message_service message.to_json
    rescue => e
      return e
    end

    # Check if passable to read and get file size
    response = @file_service_session.get_decrypted_service_response
    if response['status'] == 'OK'
      file_size = response['file_stream_size']

      # Tell FileServer we are ready to begin download
      message = { :status => 'OK' }
      @file_service_session.securely_message_service message.to_json

      # Begin download
      file = download_and_decrypt_file file_size, @file_service_session.authentication_data['session_key'], @file_service_session.service_socket
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
                    find_encrypted_file_stream_size(content, @file_service_session.authentication_data['session_key']) }
    begin
      @file_service_session.securely_message_service message.to_json
    rescue => e
      return e
    end

    # Await response from server
    response = @file_service_session.get_decrypted_service_response
    if response['status'] == 'OK'
      # Server is ready for the upload, bombs away!
      LOGGER.log 'Beginning to stream to server'
      message = { :file_content => content }
      @file_service_session.service_socket.write SimpleCipher.encrypt_message message.to_json, @file_service_session.authentication_data['session_key']

      LOGGER.log 'Awaiting download confirmation from server'
      return @file_service_session.get_decrypted_service_response
    else
      return response
    end
  end

  def disconnect
    message = { :action => 'disconnect' }
    @file_service_session.securely_message_service message.to_json
    @file_server_socket.close()
  end

end
