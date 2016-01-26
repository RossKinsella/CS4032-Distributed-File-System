require 'json'
require 'time'
require 'digest/sha1'
require '../simple_cipher.rb'
require '../logger.rb'
require '../thread_pool.rb'

SERVICE_CONNECTION_DETAILS = {
  "authentication" => {
    "ip" => "127.0.0.1", 
    "port" => "37335"
  },
  "file" => {
    "ip" => "127.0.0.1", 
    "port" => "33355"
  }  
}

LOGGER = CustomLogger.new()

def get_message_param message, param
  param_start = message.index param
  param_end = -1

  if message[param_start..-1].include? ","
    param_end = message[param_start..-1].index(",") + param_start
  elsif message[param_start..-1].include? "\n"
    param_end = message[param_start..-1].index("\n") + param_start
  end

  res = message[param_start..param_end]
  res = res.gsub(param << ":", "")
  res = res.gsub(param << ": ", "")

  if res.include? "\n"
    res.gsub! "\n", ""
  end
  if res.include? ","
    res.gsub! ",", ""
  end
  res.strip
end

# For reasons I do not understand, recv() breaks when the message is large.
def get_read_body headers, socket
  num_lines = get_message_param headers, "NUM_LINES"
  lines = []

  num_lines.to_i.times do
    lines << socket.gets
  end
  lines.join
end

def generate_key
  SecureRandom.uuid.gsub("-", "").hex
end