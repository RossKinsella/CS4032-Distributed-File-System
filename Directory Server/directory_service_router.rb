class DirectoryServiceRouter

  def self.route service, session, message
    action = message['action']

    if action == 'lookup'
      LOGGER.log 'Looking up file'
      service.lookup session, message

    elsif action == 'add entry'
      LOGGER.log 'Creating file entry'
      service.add_entry session, message

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