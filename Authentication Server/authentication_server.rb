require_relative '../common/utils.rb'
require_relative './auth_service.rb'

class AuthServer

  def initialize

    auth_service = AuthService.new
    server = TCPServer.new(
      SERVICE_CONNECTION_DETAILS['authentication']['ip'],
      SERVICE_CONNECTION_DETAILS['authentication']['port'])
    LOGGER.log "\n ############### \n Starting Auth Server \n ###############"
    LOGGER.log "Listening on #{SERVICE_CONNECTION_DETAILS['authentication']['ip']}:#{SERVICE_CONNECTION_DETAILS['authentication']['port']}"

    loop do
      Thread.start(server.accept) do |user_socket|
        begin
          LOGGER.log '//////////// Auth Server: Accepted connection ////////////////'
          message = user_socket.gets()
          if message == ''
            LOGGER.log 'Empty message recieved. Disconnecting client.'
            user_socket.close()
          elsif message.include? "KILL_SERVICE\n"
            LOGGER.log 'Killing service'
            # Do it in a new thread to prevent deadlock
            Thread.new do
              pool.shutdown
              exit
            end
          else
            begin
              auth_service.login user_socket, JSON.parse(message)
            rescue => e
              LOGGER.log e
              LOGGER.log e.backtrace.join "\n"
            end
          end
          LOGGER.log "/////////////////// Auth Service: Disconnecting user //////////////////"
          user_socket.close()
        end
      end
    end
  end

end
