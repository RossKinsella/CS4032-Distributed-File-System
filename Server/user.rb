require '../utils.rb'

class User
  attr_accessor :client_socket, :current_open_file, :session_key

  def initialize socket
    @client_socket = socket
    @current_open_file = nil
  end

  def open_file message
    file_path = get_message_param message, "PATH"
    begin
      file = File.open file_path
      @current_open_file = file
      securely_message_client "OK: Opened file at #{file_path}\n"
    rescue
      new_file file_path
    end
  end

  def close_file
    @current_open_file = nil
    securely_message_client "OK: File closed"
  end

  def read_file
    if @current_open_file
      file_content = @current_open_file.read
      headers = "STATUS:OK, NUM_LINES:#{file_content.lines.count}"
      @client_socket.puts headers << "\n" << file_content
    else
      headers = "STATUS:ERROR"
      @client_socket.puts headers
    end
  end

  def write_to_file message
    begin
      headers = message.lines.find {|l| l.include? "WRITE"}
      @current_open_file = File.open @current_open_file.path, "w"
      @current_open_file.write get_read_body headers, @client_socket
      @current_open_file.close()
      @current_open_file = File.open @current_open_file.path
      securely_message_client "OK: Write to file successful"
    rescue
      securely_message_client "Error: A problem occured whilst writing to a file"
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
        user.socket.puts "OK: New file created at #{file_path}\n"
      rescue
        user.socket.puts "Error: Cannot create file at #{file_path}\n"
      end
    end

    def securely_message_client message
      client_socket.puts SimpleCipher.encrypt_message message, @session_key
    end

end