class FileServiceRouter

  def self.route file_service, request, session
    action = request['action']

    if action == 'open'
      LOGGER.log 'Opening file'
      file_service.open_file session, request

    elsif action == 'close'
      LOGGER.log 'Closing file'
      file_service.close_file session

    elsif action == 'read'
      LOGGER.log 'Reading file'
      file_service.read_file session

    elsif action == 'write'
      LOGGER.log 'Writing to file'
      file_service.write_to_file session, request

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
