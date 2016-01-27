require '../utils.rb'

class User
  attr_accessor :client_socket, :current_open_file, :session_key

  def initialize socket
    @client_socket = socket
    @current_open_file = nil
  end

  def open_file message
    file_path = message['path']
    begin
      file = File.open file_path
      @current_open_file = file
      message = { :status => 'OK', :content => "Opened file at #{file_path}" }
      securely_message_client message.to_json
    rescue
      new_file file_path
    end
  end

  def close_file
    @current_open_file = nil
    message = { :status => 'OK', :content => 'File has been closed' }
    securely_message_client message.to_json
  end

  def read_file
    if @current_open_file
      file_content = @current_open_file.read.to_s
      # Tell client that download will go through and how large the file will be.
      message = { :status => 'OK', :file_stream_size => find_encrypted_file_stream_size(file_content, @session_key) }
      securely_message_client message.to_json

      # Await go ahead from client. We don't care what he says for now.
      read_socket_stream @client_socket

      # Send the file down the stream.
      file_stream = { :file_content => file_content }
      securely_message_client file_stream.to_json
    else
      message = { :status => 'ERROR', :content => 'Could not read file' }
      @client_socket.write message.to_json
    end
  end

  def write_to_file message
    begin
      if !@current_open_file
        message = { :status => 'error', :content => 'No file is currently open. Cannot write to file.' }
        securely_message_client message
        return
      end

      file_stream_size = message['file_stream_size']

      # Tell client they are clear to upload
      message = { :status => 'OK' }
      securely_message_client message.to_json

      file_content_message = download_and_decrypt_file file_stream_size, @session_key, @client_socket

      write_to_current_file file_content_message['file_content']

      # Tell client we are done
      message = { :status => 'OK', :content => 'Write to file successful' }
      securely_message_client message.to_json
    rescue => e
      message = { :status => 'ERROR', :content => "#{e}" }
      securely_message_client message.to_json
    end
  end

  def disconnect
    @client_socket.close()
  end

  def is_connected
    !@client_socket.closed?
  end

  private

    def new_file file_path
      begin
        @current_open_file = File.new file_path, "w+"
        message = { :status => 'OK', :content => "New file created at #{file_path}" }
        securely_message_client message.to_json
      rescue
        message = { :status => 'ERROR',
                    :content => "Cannot create file at #{file_path}. Does it already exist?" }
        securely_message_client message.to_json
      end
    end

    def write_to_current_file content
      @current_open_file = File.open @current_open_file.path, 'w'
      @current_open_file.write content
      @current_open_file.close()
      @current_open_file = File.open @current_open_file.path
    end

    def securely_message_client message
      client_socket.write SimpleCipher.encrypt_message message, @session_key
    end

end
