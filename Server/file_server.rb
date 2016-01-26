require 'socket'
require 'securerandom'
require 'json'
require './file_service.rb'
require '../utils.rb'
require './user.rb'

# ip_address = '134.226.32.10'
submit_id = "0105a7b6c410f4f3ae2d2acab136fa2744b7b80012e46ff3214ebb93579a1abc"

pool = ThreadPool.new(10)
file_service = FileService.new Digest::SHA1.hexdigest "__Thor__password__"
server = TCPServer.new(
  SERVICE_CONNECTION_DETAILS['file']['ip'],
  SERVICE_CONNECTION_DETAILS['file']['port'])

LOGGER.log "Starting File Server"
LOGGER.log "Listening on #{SERVICE_CONNECTION_DETAILS['file']['ip']}:#{SERVICE_CONNECTION_DETAILS['file']['port']}"

loop do
  pool.schedule do
    begin
      user_socket = server.accept_nonblock
      user = User.new user_socket

      LOGGER.log "//////////// Accepted connection ////////////////"

      while user.is_connected
        begin
          message = user.client_socket.gets()
          if message == ""
            LOGGER.log "Empty message recieved. Disconnecting user."
            user.disconnect()
          elsif message.include? "KILL_SERVICE\n"
            LOGGER.log "Killing service"
            # Do it in a new thread to prevent deadlock
            Thread.new do
              pool.shutdown
              exit
            end
          else
            begin
              # temp hack
              if message.include? "WRITE"
                file_service.handle_messages(user, message)
              else
                file_service.handle_messages(user, JSON.parse(message))
              end
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