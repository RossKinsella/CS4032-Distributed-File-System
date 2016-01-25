require 'socket'
require 'securerandom'
require './thread_pool.rb'
require './file_service.rb'
require '../logger.rb'
require './user.rb'

# ip_address = '134.226.32.10'
ip_address = '127.0.0.1'
port = '33355'
submit_id = "0105a7b6c410f4f3ae2d2acab136fa2744b7b80012e46ff3214ebb93579a1abc"

logger = Logger.new
pool = ThreadPool.new(10)
file_service = FileService.new pool
server = TCPServer.new ip_address, port
logger.log "Listening on #{ip_address}:#{port}"

loop do
  pool.schedule do
    begin
      user_socket = server.accept_nonblock
      user = User.new user_socket

      logger.log "//////////// Accepted connection ////////////////"

      while user.is_connected
        begin
          message = user.socket.recv 1000
          logger.log "//////Message: ///////\n" << message << "/////////////"
          if message.include? "KILL_SERVICE\n"
            logger.log "Killing service"
            # Do it in a new thread to prevent deadlock
            Thread.new do
              pool.shutdown
              exit
            end
          elsif message.include? "HELO"
            message.gsub "HELO ", ""
            logger.log "Giving data dump"
            user.socket.puts message << "IP:#{ip_address}\nPort:#{port.to_s}\nStudentID:#{submit_id}"
          else
            begin
              file_service.handle_messages user, message
            rescue => e
              logger.log e
            end
          end
          logger.log "Finished handling message: " << message
       rescue
         # logger.log "No message found.. Going to sleep..."
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