require_relative '../Common/utils'

class DirectoryServerBalencer

  attr_accessor :file_servers

  def initialize
    @file_servers = SERVICE_CONNECTION_DETAILS['file_servers'] # utils stuff
    @last_server_allocated = 0
  end

  def select_server
    server = @file_servers[@last_server_allocated]
    @last_server_allocated += 1
    @last_server_allocated = @last_server_allocated % @file_servers.size
    server
  end

end