class ServiceSession
  attr_accessor :client_socket, :service, :current_open_file, :key

  def initialize socket, service
    @client_socket = socket
    @service = service
  end

  def get_request
    message = @client_socket.gets()
    
    begin
      message = JSON.parse message
    rescue => e
      LOGGER.log 'Bad message recieved.' << e # Message wasn't json or it was empty
      disconnect
    end

    if !authenticated? message
      Logger.log 'Unauthorized message'
      raise 'Unauthorised message'
    end

    decrypted_message = SimpleCipher.decrypt_message message['request'], @key
    LOGGER.log LOGGER.log "#{@service.name} has received a secure message: #{decrypted_message.truncate(180)}"
    JSON.parse decrypted_message
  end

  def authenticated? message
    if !message['ticket']
      LOGGER.log 'No ticket found, rejecting request.'
      @client_socket.puts 'No ticket found, your request has been rejected.'
      return false
    else
      @key = SimpleCipher.decrypt_message message['ticket'], @service.key
      return true
    end
  end

  def write_to_current_file content
    @current_open_file = File.open @current_open_file.path, 'w'
    @current_open_file.write content
    @current_open_file.close()
    @current_open_file = File.open @current_open_file.path
  end

  def securely_message_client message
    @client_socket.write SimpleCipher.encrypt_message message, @key
    LOGGER.log "#{@service.name} has just send a secure message: #{message.truncate(180)}"
  end

  def disconnect
    LOGGER.log "/////////////////// #{service.name}: Disconnecting user //////////////////"
    @client_socket.close()
  end

  def is_connected
    !@client_socket.closed?
  end

end
