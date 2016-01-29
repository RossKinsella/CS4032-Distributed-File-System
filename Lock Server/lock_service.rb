class LockService

  attr_accessor :name, :key

  def initialize name, key
    @name = name
    @key = key

    database_file_path = '../Directory Server/database.json'
    @database = DirectoryDatabase.from_json File.open(database_file_path).read
    initialize_locks_hash
  end

  def attempt_lock session, request
    file_id = request['file_id']
    if !locked? file_id
      @locks[file_id] = true
      message = {
        'status' => 'granted'
      }
    else
      message = {
        'status' => 'denied'
      }
    end
    session.securely_message_client message.to_json
  end

  def unlock session, request
    file_id = request['file_id']
    @locks[file_id] = false
    message = {
      'status' => 'OK'
    }
    session.securely_message_client message.to_json
  end

  def update_directory session, request
    old_entries = @database.entries
    old_entry_ids = []
    old_entries.each do |entry|
      old_entry_ids << entry.file_id
    end

    directory_database_serialized = request['directory_database_serialized']
    @database = DirectoryDatabase.from_json directory_database_serialized
    all_entries = @database.entries
    all_entry_ids = []
    all_entries.each do |entry|
      all_entry_ids << entry.file_id
    end

    new_entry_ids = all_entry_ids - old_entry_ids
    update_locks_hash new_entry_ids
  end

  private

    def locked? file_id
      @locks[file_id]
    end

    # Returns a lookup table of file_id : semaphore
    def initialize_locks_hash
      @locks = {}
      @database.entries.each do |entry|
        @locks[entry.file_id] = false
      end
    end

    def update_locks_hash new_entry_ids
      new_entry_ids.each do |entry|
        @locks[entry] = false
      end
    end

end