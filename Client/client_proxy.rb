require '../utils.rb'

class ClientProxy
  attr_accessor :server_socket

  def initialize
    @server_socket = TCPSocket.open('127.0.0.1', 33355)
  end

  def open file_path
    @server_socket.puts "OPEN:\nPATH: #{file_path}"
    @server_socket.recv(1000)
  end

  def close

  end

  def read
    @server_socket.puts "READ"

    headers = @server_socket.gets()
    status = get_message_param headers, "STATUS"
    if status == "OK"
      return get_read_body headers
    else
      return "Server Error."
    end
  end

  def write content

  end

  def disconnect
    @server_socket.puts "DISCONNECT"
    @server_socket.close()
  end

  private

    # For reasons I do not understand, recv() breaks when the message is large.
    def get_read_body headers
      num_lines = get_message_param headers, "NUM_LINES"
      lines = []

      num_lines.to_i.times do
        lines << @server_socket.gets
      end
      lines.flatten
    end

end