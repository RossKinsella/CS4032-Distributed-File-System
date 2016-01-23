require 'socket'
require 'securerandom'
require './thread_pool.rb'
require './file_service.rb'
require './logger.rb'

# ip_address = '134.226.32.10'
ip_address = '127.0.0.1'
port = '33352'
submit_id = "0105a7b6c410f4f3ae2d2acab136fa2744b7b80012e46ff3214ebb93579a1abc"

logger = Logger.new
pool = ThreadPool.new(10)
file_service = FileService.new pool
server = TCPServer.new ip_address, port
logger.log "Listening on #{ip_address}:#{port}"

loop do
  pool.schedule do
    begin
      client = server.accept_nonblock
      logger.log "//////////// Accepted connection ////////////////"

      while true
        # logger.log "Awaiting message..."
        begin
          message = client.recv(1000)
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
            client.logger.log message << "IP:#{ip_address}\nPort:#{port.to_s}\nStudentID:#{submit_id}"
          else
            file_service.handle_messages client, message
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