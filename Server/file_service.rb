require '../utils.rb'

class FileService  

  def initialize key
    @key = key
  end

  def handle_messages user, message
    if message.include? "DISCONNECT"
      LOGGER.log "Disconnecting user"
      user.disconnect()
      return
    end

    if !message['ticket']
      LOGGER.log "No ticket found, rejecting request."
      user.client_socket.puts "No ticket found, your request has been rejected."
      return
    else
      session_key = SimpleCipher.decrypt_message message['ticket'], @key
      user.session_key = session_key
      request = SimpleCipher.decrypt_message message['request'], session_key
    end

    if request.include? "OPEN"
      LOGGER.log "Opening file"
      user.open_file request

    elsif request.include? "CLOSE"
      LOGGER.log "Closing file"
      user.close_file()

    elsif request.include? "READ"
      LOGGER.log "Reading file"
      user.read_file()

    elsif request.include? "WRITE"
      LOGGER.log "Writing to file"
      user.write_to_file request

    else
      LOGGER.log "Unsupported message."
      user.client_socket.puts "Unsupported message"
    end
  end

end