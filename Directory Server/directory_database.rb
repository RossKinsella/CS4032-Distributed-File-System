require_relative './directory_server_balencer'
require_relative './directory_user_entry'

class DirectoryDatabase
  attr_accessor :users, :iterator

  def initialize attrs={}
    @users = {}
    attrs['users'].each do |user|
      @users[user[0]] = DirectoryUserEntry.new user[1]
    end
    @iterator = attrs['iterator']
    @directory_server_balencer = DirectoryServerBalencer.new
  end

  def lookup request
    # Find the DirectoryUserEntry
    if @users[request['user_name']]
      user = @users[request['user_name']]
      # Find the DirectoryEntry
      if user.entries[request['user_file_path']]
        entry = user.entries[request['user_file_path']]
        return {
          'status' => 'OK',
          'content' => entry.to_hash
        }
      end
    end

    return {
      'status' => 'ERROR',
      'content' => 'Could not find an entry.'
    }
  end

  def add_entry request
    # Find the DirectoryUserEntry
    user = find_user request['user_name']
    server = @directory_server_balencer.select_server

    new_entry_params = {
        'user_name' => request['user_name'],
        'user_file_path' => request['user_file_path'],
        'file_id' => @iterator+=1,
        'file_server_name' => server['name'],
        'file_server_ip' => server['ip'],
        'file_server_port' => server['port']
    }

    begin
      entry = user.create_entry new_entry_params
      save
      return {
        'status' => 'OK',
        'content' => entry.to_hash
      }
    rescue => e
      return {
          'status' => 'ERROR',
          'content' => e.to_s
      }
    end
  end

  def save
    state = to_json
    database_file_path = File.join File.dirname(__FILE__), 'database.json'
    save_file = File.open(database_file_path, 'w')
    save_file.write state
    save_file.close
  end

  def to_hash
    hash = { 'users' => @users.to_hash, 'iterator' => @iterator }
    if hash['users']
      hash['users'].each do |user|
        hash['users'][user[0]] = user[1].to_hash
      end
    end
    hash
  end

  def to_json
    JSON.pretty_generate to_hash
  end

  def self.from_json json
    attrs = JSON.parse json
    DirectoryDatabase.new attrs
  end

  private

    def find_user user_name
      user = nil
      if @users[user_name]
        user = @users[user_name]
      else
        # User not found. Create it.
        # Assumption: Usernames are unique
        user = add_user user_name
        users[user_name] = user
      end
      user
    end

    def add_user user_name
      params = { :user_name => user_name, :entries => {} }
      DirectoryUserEntry.new params
    end

    def self.existing_identifiers
      ids = []
      @users.each |user|
        user.entries.each |entry|
          ids << entry
    end

end
