require '../utils.rb'

class User
  attr_accessor :socket, :current_open_file

  CHUNK_SIZE = 1000

  def initialize socket
    @socket = socket
    @current_open_file = nil
  end

  def new_file file_path
    begin
       @current_open_file = File.new file_path, "w+"
      user.socket.puts "OK: New file created at #{file_path}\n"
    rescue
      user.socket.puts "Error: Cannot create file at #{file_path}\n"
    end
  end

  def open_file message
    file_path = get_message_param message, "PATH"
    begin
      file = File.open file_path
      @current_open_file = file
      @socket.puts "OK: Opened file at #{file_path}\n"
    rescue
      new_file file_path
    end
  end

  def close_file
    @current_open_file = nil
    @socket.puts "OK: File closed"
  end

  def read_file
    if @current_open_file
      file_content = @current_open_file.read
      headers = "STATUS:OK, NUM_LINES:#{file_content.lines.count}"
      @socket.puts headers << "\n" << file_content
    else
      headers = "STATUS:ERROR"
      @socket.puts headers
    end
  end

  def write_to_file message
    begin
x      headers = message.lines.find {|l| l.include? "WRITE"}
      @current_open_file = File.open @current_open_file.path, "w"
      @current_open_file.write get_read_body headers
      @current_open_file.close()
      @current_open_file = File.open @current_open_file.path
      @socket.puts "OK: Write to file successful"
    rescue
      @socket.puts "Error: A problem occured whilst writing to a file"
    end
  end

  def disconnect
    @socket.close()
  end

  def is_connected
    !@socket.closed?
  end

end