class Router

  def self.route server, request, session
    action = request['action']

    if action == 'open'
      LOGGER.log 'Opening file'
      server.open_file session, request

    elsif action == 'close'
      LOGGER.log 'Closing file'
      server.close_file session

    elsif action == 'read'
      LOGGER.log 'Reading file'
      server.read_file session

    elsif action == 'write'
      LOGGER.log 'Writing to file'
      server.write_to_file session, request

    elsif action == 'disconnect'
      LOGGER.log 'Disconnection request received'
      session.disconnect
      return

    elsif action == 'shut_down'
      LOGGER.log 'Killing service'
      # Do it in a new thread to prevent deadlock
      Thread.new do
        pool.shutdown
        exit
      end

    else
      LOGGER.log 'Unsupported action.'
      session.client_socket.write 'Unsupported action'

    end

  end

end
