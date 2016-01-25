require '../utils.rb'

class User
  attr_accessor :socket, :current_open_file

  CHUNK_SIZE = 1000

  def initialize socket
    @socket = socket
    @current_open_file = nil
  end

  def close_file
    @current_open_file = nil
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

  def disconnect
    @socket.close()
  end

  def is_connected
    !@socket.closed?
  end

end