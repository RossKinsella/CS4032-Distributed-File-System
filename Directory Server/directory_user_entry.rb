require_relative '../Directory Server/directory_entry'

class DirectoryUserEntry

  attr_accessor :user_name, :entries

  def initialize params = {}
    @user_name = params['user_name']
    @entries = {}
    if params['entries']
      params['entries'].each do |entry|
        @entries[entry[0]] = DirectoryEntry.new entry[1]
      end
    end
  end

  def create_entry params = {}
    entry = DirectoryEntry.new params
    @entries[entry.user_file_path] = entry
    entry
  end

  def to_hash
    hash = {
        'user_name' => @user_name,
        'entries' => @entries.to_hash
    }
    if hash['entries']
      hash['entries'].each do |entry|
        hash['entries'][entry[0]] = entry[1].to_hash
      end
    end
    hash
  end

  def to_json
    to_hash.to_json
  end

  def self.from_json json
    attrs = JSON.parse json
    DirectoryUserEntry.new attrs
  end

end
