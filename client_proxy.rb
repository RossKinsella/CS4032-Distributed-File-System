class ClientProxy

  def init
    @server = TCPSocket.open('127.0.0.1', 33352)
  end

  def open file_path
    file
  end

  def close

  end

  def read
    file_content
  end

  def write content

  end

end