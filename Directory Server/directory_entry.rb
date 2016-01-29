class DirectoryEntry
  attr_accessor :user_name, :user_file_path, :file_id, :file_server_name, :file_server_ip, :file_server_port

  def initialize params = {}
    @user_name = params['user_name']
    @user_file_path = params['user_file_path']
    @file_server_name = params['file_server_name']
    @file_server_ip = params['file_server_ip']
    @file_server_port = params['file_server_port']
    @file_id = params['file_id']
  end

  def to_hash
    { 
      'user_name' => @user_name, 
      'user_file_path' => @user_file_path,
      'file_server_name' => @file_server_name,
      'file_server_ip' => @file_server_ip,
      'file_server_port' => @file_server_port,
      'file_id' => @file_id
    }  
  end

  def to_json
    to_hash.to_json
  end

  def self.from_json json
    attrs = JSON.parse json
    DirectoryEntry.new attrs
  end

end
