require './logger.rb'

class FileService  

  def initialize(thread_pool)
    @pool = thread_pool # TODO: Why do I do this in here... In other labs you did it in the server?
    @logger = Logger.new
  end

  def handle_messages client, message
    logger.log "handle messages"

    if message.include? "KILL_SERVICE"
      logger.log "Killing service..."
      Thread.new do
        # Do it in a new thread to prevent deadlock
        # TODO: Why do I do this in here... In other labs you did it in the server?
        @pool.shutdown
        exit
      end
    # elsif message.include? "JOIN_CHATROOM:"
    #   logger.log "Client is joining a chatroom...."
    else
      logger.log "Unsupported message."
      client.puts "go away\nseriously, get lost\nBEGONE"
      logger.log "Did nothing."
    end
  end 

  def generate_identifier
    SecureRandom.uuid.gsub("-", "").hex
  end

  def get_message_param message, param
    param_start = message.index param
    param_end = -1
    if message[param_start..-1].include? "\n"
      param_end = message[param_start..-1].index("\n") + param_start
    end

    res = message[param_start..param_end]
    res = res.gsub(param << ":", "")
    res = res.gsub(param << ": ", "")
    
    if res.include? "\n"
      res.gsub! "\n", ""
    end
    res
  end
end