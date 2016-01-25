require '../logger.rb'
require '../utils.rb'

class FileService  

  def initialize(thread_pool)
    @pool = thread_pool # TODO: Why do I do this in here... In other labs you did it in the server?
    @logger = Logger.new
  end

  def handle_messages user, message
    @logger.log "handle messages"

    if message.include? "KILL_SERVICE"
      @logger.log "Killing service..."
      Thread.new do
        # Do it in a new thread to prevent deadlock
        # TODO: Why do I do this in here... In other labs you did it in the server?
        @pool.shutdown
        exit
      end
    elsif message.include? "DISCONNECT"
      user.disconnect()
    elsif message.include? "OPEN"
      @logger.log "Begin open"
      file_path = get_message_param message, "PATH"
      file = File.open file_path
      # Todo - what if new file, should have empty file_path.
      if file
        user.current_open_file = file
        user.socket.puts "200\n"
      else
        user.socket.puts "error: file not found"
      end
      @logger.log "End open"
    elsif message.include? "CLOSE"
      @logger.log "Begin close"
      file = File.open "lorem.html"
      user.socket.puts file.read
      @logger.log "End close"
    elsif message.include? "READ"
      @logger.log "Begin read"
      user.read_file()
      @logger.log "End read"
    elsif message.include? "WRITE"
      @logger.log "Begin write"
      file = File.open "lorem.html"
      user.socket.puts file.read
      @logger.log "End write"
    else
      @logger.log "Unsupported message."
      @logger.log "Did nothing."
    end
  end 

  def generate_identifier
    SecureRandom.uuid.gsub("-", "").hex
  end

end