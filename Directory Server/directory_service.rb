require '../common/utils.rb'
require_relative './directory_database'

class DirectoryService

  attr_accessor :name, :key

  def initialize name, key
    @name = name
    @key = key

    database_file_path = File.join File.dirname(__FILE__), 'database.json'
    @database = DirectoryDatabase.from_json File.open(database_file_path).read
  end

  def lookup session, message
    LOGGER.log "Doing lookup: #{message}"
    response = @database.lookup message
    if response['status'] == 'ERROR'
      response = @database.add_entry message
    end
    session.securely_message_client response.to_json
  end

  def add_entry session, message
    LOGGER.log "Adding entry lookup: #{message}"
    response = @database.add_entry message
    session.securely_message_client response.to_json
  end

end