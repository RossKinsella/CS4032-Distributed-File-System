require 'socket'
require 'json'
require 'time'
require 'digest/sha1'
require 'securerandom'
require_relative './simple_cipher.rb'
require_relative './logger.rb'
require_relative './thread_pool.rb'
require_relative './client_session.rb'
require_relative './service_session.rb'

# File server passwords would be hidden from the world in a real environment.
# For simplicity I have made them public though.
SERVICE_CONNECTION_DETAILS = {
  'authentication' => {
    'ip' => '127.0.0.1',
    'port' => '37335'
  },
  'file_servers' => [
      {
          'name' => 'Thor',
          'ip' => '127.0.0.1',
          'port' => '33355'
      },
      {
          'name' => 'Zeus',
          'ip' => '127.0.0.1',
          'port' => '23315'
      },
      {
          'name' => 'Hermes',
          'ip' => '127.0.0.1',
          'port' => '46778'
      }
  ],
  'directory' => {
      'ip' => '127.0.0.1',
      'port' => '12223'
  },
  'lock' => {
      'ip' => '127.0.0.1',
      'port' => '42882'
  }
}

def get_service_id service
  service['ip'] + ':' + service['port']
end

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

def download_stream socket
  while socket.recv 1000

  end
end

def read_socket_stream socket
  stream = ''

  # Wait for response
  while !next_line_readable? socket
    sleep 0.5
  end

  # Gather full stream
  while next_line_readable? socket
    stream << socket.recv(1000)
  end

  stream
end

def download_streamed_file socket, file_size
  LOGGER.log "Queueing download of file sized #{file_size} bytes"
  stream = ''

  # Wait for response
  while !next_line_readable? socket
    LOGGER.log 'Awaiting stream to begin..'
    sleep 0.5
  end

  # Gather full stream
  LOGGER.log 'Stream has begun...'
  last_percentage_update = Time.now
  percentage_update_cooldown = 1

  while stream.size != file_size
    if (last_percentage_update + percentage_update_cooldown) < Time.now
      percent_complete = (stream.size.to_f / file_size.to_f * 100.to_f).to_i
      LOGGER.log "Download is at #{percent_complete}%"
      last_percentage_update = Time.now
    end
    stream << socket.recv(2500000)
  end
  
  LOGGER.log 'Download is at 100%'
  stream
end

def next_line_readable?(socket)
  readfds = select([socket], nil, nil, 0.1)
  readfds #Will be nil if next line cannot be read
end

def download_and_decrypt_file file_size, key, socket
  file = download_streamed_file socket, file_size
  JSON.parse SimpleCipher.decrypt_message file, key
end

def find_encrypted_file_stream_size file_content, key
  file_stream = generate_file_stream_message file_content
  encrypted = SimpleCipher.encrypt_message file_stream, key
  encrypted.size
end

def generate_file_stream_message file_content
  { :file_content => file_content }.to_json
end

class String
  def truncate(max)
    length > max ? "#{self[0...max]}..." : self
  end
end

def generate_file_name
  RandomWord.nouns.next
end

def generate_file_content
  RandomWord.nouns.next + ' ' + RandomWord.adjs.next
end
