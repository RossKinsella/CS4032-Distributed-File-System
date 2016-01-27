require_relative '../utils.rb'
require_relative './auth_service.rb'

class AuthServer

  def initialize

    pool = ThreadPool.new(10)
    auth_service = AuthService.new
    server = TCPServer.new(
      SERVICE_CONNECTION_DETAILS['authentication']['ip'],
      SERVICE_CONNECTION_DETAILS['authentication']['port'])
    LOGGER.log "############### \n Starting Auth Server \n ###############"
    LOGGER.log "Listening on #{SERVICE_CONNECTION_DETAILS['authentication']['ip']}:#{SERVICE_CONNECTION_DETAILS['authentication']['port']}"

    loop do
      pool.schedule do
        begin
          client_socket = server.accept_nonblock

          LOGGER.log '//////////// Auth Server: Accepted connection ////////////////'

          while !client_socket.closed?
            begin
              message = client_socket.gets()
              if message == ''
                LOGGER.log 'Empty message recieved. Disconnecting client.'
                client_socket.close()
              elsif message.include? "KILL_SERVICE\n"
                LOGGER.log 'Killing service'
                # Do it in a new thread to prevent deadlock
                Thread.new do
                  pool.shutdown
                  exit
                end
              else
                begin
                  auth_service.login client_socket, JSON.parse(message)
                rescue => e
                  LOGGER.log e
                  LOGGER.log e.backtrace.join "\n"
                end
              end

            rescue
              # Dont starve the other threads you dick...
              sleep(2)
            end
          end

        rescue
          # DO NOTHING
        end
      end
    end

    at_exit { pool.shutdown }
  end
end
