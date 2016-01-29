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
      add_entry session, message
    else
      session.securely_message_client response.to_json
    end
  end

  def add_entry session, message
    LOGGER.log "Adding entry: #{message}"
    response = @database.add_entry message
    session.securely_message_client response.to_json
    inform_lock_service_of_new_entry
  end

  def inform_lock_service_of_new_entry
    LOGGER.log 'Directory service is about to inform the lock service of a new entry in the file system'
    session = ClientSession.new(
      SERVICE_CONNECTION_DETAILS['lock']['ip'],
      SERVICE_CONNECTION_DETAILS['lock']['port'],
      @name,
      @key)

    message = {
      'action' => 'update_directory',
      'directory_database_serialized' => @database.to_json
    }

    session.securely_message_service message.to_json
  end

end