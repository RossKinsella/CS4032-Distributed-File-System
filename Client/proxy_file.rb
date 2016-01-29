require_relative '../common/utils.rb'
require 'digest/sha1'

class ProxyFile

  attr_accessor :file_service_session, :directory_data

  FILE_SERVER_NAME = 'Thor'

  def initialize file_service_session, directory_data
    @file_service_session = file_service_session
    @directory_data = directory_data
  end

  def self.login username, password
    @@username = username
    @@key = Digest::SHA1.hexdigest(password)
  end

  # Finds the directory information for that path, creates a ClientSession with the
  # appropriate file server and returns a ProxyFile.
  def self.open file_path
    LOGGER.log "\n###### #{@@username} is opening #{file_path} ######\n"

    if !self.loggedin?
      raise 'You must first login before attempting to open a file'
    end

    directory_data = get_directory_data file_path

    file_service_session = ClientSession.new(
        directory_data['file_server_ip'],
        directory_data['file_server_port'],
        @@username,
        @@key)

    message = { :action => 'open', :id => "#{directory_data['file_id']}" }
    begin
      file_service_session.securely_message_service message.to_json
    rescue => e
      return e
    end
    LOGGER.log file_service_session.get_decrypted_service_response
    ProxyFile.new file_service_session, directory_data
  end

  def self.loggedin?
    @@username && @@key
  end

  def close
    LOGGER.log "\n###### #{@@username} is closing his current file ######\n"
    message = { :action => 'close' }
    begin
      @file_service_session.securely_message_service message.to_json
    rescue => e
      return e
    end
    LOGGER.log @file_service_session.get_decrypted_service_response
    @file_service_session.end
  end

  def read
    LOGGER.log "\n###### #{@@username} is reading his current file ######\n"
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
    LOGGER.log "\n###### #{@@username} is writing to his current file ######\n"

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
      LOGGER.log @file_service_session.get_decrypted_service_response
    else
      LOGGER.log response
    end
  end

  private

    def self.get_directory_service_session
      ClientSession.new(
          SERVICE_CONNECTION_DETAILS['directory']['ip'],
          SERVICE_CONNECTION_DETAILS['directory']['port'],
          @@username,
          @@key)
    end

    def self.get_directory_data file_path
      directory_session = get_directory_service_session
      message = {
          :action => 'lookup',
          :user_name => "#{@@username}",
          :user_file_path => "#{file_path}"
      }
      directory_session.securely_message_service message.to_json
      data = directory_session.get_decrypted_service_response['content']
      directory_session.end
      data
    end

end
