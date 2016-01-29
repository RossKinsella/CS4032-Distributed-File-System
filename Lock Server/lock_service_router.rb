class LockServiceRouter

  def self.route service, message, session
    action = message['action']

    if action == 'lock'
      LOGGER.log 'Attempting to lock a file'
      service.attempt_lock session, message

    elsif action == 'unlock'
      LOGGER.log 'Attempting to unlock a file'
      service.unlock session, message

    elsif action == 'update_directory'
      LOGGER.log 'Updating directory'
      service.update_directory session, message

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