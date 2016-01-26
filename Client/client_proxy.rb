require '../utils.rb'

class ClientProxy
  attr_accessor :server_socket

  def initialize
    @socket = TCPSocket.open '127.0.0.1', 33355
  end

  def open file_path
    @socket.puts "OPEN; PATH: #{file_path}"
    @socket.recv 1000
  end

  def close
    @socket.puts "CLOSE"
    @socket.recv 1000
  end

  def read
    @socket.puts "READ"

    headers = @socket.gets()
    status = get_message_param headers, "STATUS"
    if status == "OK"
      return get_read_body headers
    else
      return "Server Error."
    end
  end

  def write content
    headers = "WRITE; NUM_LINES:#{content.lines.count}"
    @socket.puts headers << "\n" << content
    @socket.recv 1000
  end

  def disconnect
    @socket.puts "DISCONNECT"
    @socket.close()
  end

end