require 'socket'
require 'securerandom'
require '../utils.rb'
require './auth_service.rb'

# ip_address = '134.226.32.10'

submit_id = "0105a7b6c410f4f3ae2d2acab136fa2744b7b80012e46ff3214ebb93579a1abc"

pool = ThreadPool.new(10)
auth_service = AuthService.new
server = TCPServer.new(
  SERVICE_CONNECTION_DETAILS['authentication']['ip'],
  SERVICE_CONNECTION_DETAILS['authentication']['port'])
LOGGER.log "Starting Auth Server"
LOGGER.log "Listening on #{SERVICE_CONNECTION_DETAILS['authentication']['ip']}:#{SERVICE_CONNECTION_DETAILS['authentication']['port']}"

loop do
  pool.schedule do
    begin
      client_socket = server.accept_nonblock

      LOGGER.log "//////////// Accepted connection ////////////////"

      while !client_socket.closed?
        begin
          message = client_socket.gets()
          if message == ""
            LOGGER.log "Empty message recieved. Disconnecting client."
            client_socket.close()
          elsif message.include? "KILL_SERVICE\n"
            LOGGER.log "Killing service"
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