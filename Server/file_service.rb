require '../utils.rb'

class FileService  

  def initialize key
    @key = key
  end

  def handle_messages user, message
    if message['request'] && message['request']['action'] && message['request']['action']['disconnect']
      LOGGER.log 'Disconnecting user'
      user.disconnect()
      return
    end

    if !message['ticket']
      LOGGER.log 'No ticket found, rejecting request.'
      user.client_socket.puts 'No ticket found, your request has been rejected.'
      return
    else
      session_key = SimpleCipher.decrypt_message message['ticket'], @key
      user.session_key = session_key
      request = JSON.parse SimpleCipher.decrypt_message message['request'], session_key
    end

    action = request['action']

    if action == 'open'
      LOGGER.log 'Opening file'
      user.open_file request

    elsif action == 'close'
      LOGGER.log 'Closing file'
      user.close_file()

    elsif action == 'read'
      LOGGER.log 'Reading file'
      user.read_file()

    elsif action == 'write'
      LOGGER.log 'Writing to file'
      user.write_to_file request

    else
      LOGGER.log 'Unsupported action.'
      user.client_socket.write 'Unsupported action'
    end
  end

end
