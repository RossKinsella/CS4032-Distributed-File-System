require '../logger.rb'
require '../utils.rb'

class FileService  

  def initialize(thread_pool)
    @pool = thread_pool # TODO: Why do I do this in here... In other labs you did it in the server?
    @logger = Logger.new
  end

  def handle_messages user, message
    if message.include? "KILL_SERVICE"
      @logger.log "Killing service..."
      Thread.new do
        # Do it in a new thread to prevent deadlock
        # TODO: Why do I do this in here... In other labs you did it in the server?
        @pool.shutdown
        exit
      end
    elsif message.include? "DISCONNECT"
      @logger.log "Disconnecting user"
      user.disconnect()
    elsif message.include? "OPEN"
      @logger.log "Opening file"
      user.open_file message

    elsif message.include? "CLOSE"
      @logger.log "Closing file"
      user.close_file()

    elsif message.include? "READ"
      @logger.log "Reading file"
      user.read_file()

    elsif message.include? "WRITE"
      @logger.log "Writing to file"
      user.write_to_file message

    else
      @logger.log "Unsupported message."
      user.socket.puts "Unsupported message"
    end
  end 

  def generate_identifier
    SecureRandom.uuid.gsub("-", "").hex
  end

end