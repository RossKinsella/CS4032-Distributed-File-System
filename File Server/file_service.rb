require '../utils.rb'

class FileService  

  attr_accessor :name, :key

  def initialize name, key
    @name = name
    @key = key
  end

  def open_file session, message
    file_path = message['path']
    file_path = File.join File.dirname(__FILE__), file_path
    begin
      file = File.open file_path
      session.current_open_file = file
      message = { :status => 'OK', :content => "Opened file at #{file_path}" }
      session.securely_message_client message.to_json
    rescue
      new_file session, file_path
    end
  end

  def close_file session
    session.current_open_file = nil
    message = { :status => 'OK', :content => 'File has been closed' }
    session.securely_message_client message.to_json
  end

  def read_file session
    if session.current_open_file
      file_content = session.current_open_file.read.to_s
      # Tell client that download will go through and how large the file will be.
      message = { :status => 'OK', :file_stream_size => find_encrypted_file_stream_size(file_content, session.key) }
      session.securely_message_client message.to_json

      # Await go ahead from client. We don't care what he says for now.
      read_socket_stream session.client_socket

      # Send the file down the stream.
      file_stream = { :file_content => file_content }
      session.securely_message_client file_stream.to_json
    else
      message = { :status => 'ERROR', :content => 'Could not read file' }
      session.client_socket.write message.to_json
    end
  end

  def write_to_file session, message
    begin
      if !session.current_open_file
        message = { :status => 'error', :content => 'No file is currently open. Cannot write to file.' }
        session.securely_message_client message
        return
      end

      file_stream_size = message['file_stream_size']

      # Tell client they are clear to upload
      message = { :status => 'OK' }
      session.securely_message_client message.to_json

      file_content_message = download_and_decrypt_file file_stream_size, session.key, session.client_socket

      session.write_to_current_file file_content_message['file_content']

      # Tell client we are done
      message = { :status => 'OK', :content => 'Write to file successful' }
      session.securely_message_client message.to_json
    rescue => e
      message = { :status => 'ERROR', :content => "#{e}" }
      session.securely_message_client message.to_json
    end
  end

  private

    def new_file session, file_path
      begin
        session.current_open_file = File.new file_path, "w"
        message = { :status => 'OK', :content => "New file created at #{file_path}" }
        session.securely_message_client message.to_json
      rescue => e
        message = { :status => 'ERROR',
                    :content => "Cannot create file at #{file_path}." << e }
        session.securely_message_client message.to_json
      end
    end

end
