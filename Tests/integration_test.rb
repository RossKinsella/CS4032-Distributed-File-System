require 'test/unit'
require '../Common/utils'
require '../File Server/file_server'
require '../Authentication Server/authentication_server'
require '../Directory Server/directory_server'
require '../Client/proxy_file'
require 'random-word'

class IntegrationTest < Test::Unit::TestCase

  SERVICE_CONNECTION_DETAILS['file_servers'].each do |details|
    Thread.new do
      begin
        FileServer.new details, AuthService.service_keys[get_service_id details]
      rescue => e
        LOGGER.log "File Server #{details[:name]}:" << e
      end
    end
  end

  Thread.new do
    begin
      AuthServer.new
    rescue => e
      LOGGER.log 'Auth Server' << e
    end
  end

  Thread.new do
    begin
      DirectoryServer.new
    rescue => e
      LOGGER.log 'Directory Server' << e
    end
  end

  # def setup
  #   directory_db = File.open '../Directory Server/database.json'
  #   @db_content = directory_db.read
  #   directory_db.close
  # end
  #
  # def teardown
  #   directory_db = File.open '../Directory Server/database.json', 'w'
  #   directory_db.write @db_content
  #   directory_db.close
  # end

  LOGGER.log 'waiting 1s to allow services to boot...'
  sleep 1 # Let the servers boot up

  def test_read
    LOGGER.log "\n ###################### \n Test: ProxyFile.read \n ######################"

    ProxyFile.login 'Joe', 'puppies'
    file = ProxyFile.open 'lorem.html'
    content = file.read
    file.close
    assert_equal content, File.open('../File Server/Thor/1').read
  end

  def test_write
    LOGGER.log "\n ###################### \n Test: ProxyFile.write \n ######################"

    ProxyFile.login 'Joe', 'puppies'
    random_file_path = generate_file_name
    file = ProxyFile.open random_file_path
    file.write File.open('../File Server/Thor/1').read
    file.close
    directory_data = file.directory_data
    file_path = "../File Server/#{directory_data['file_server_name']}/#{directory_data['file_id']}"
    assert_equal File.open('../File Server/Thor/1').read, File.open(file_path).read
  end

  # Due to repo size limits I couldn't include a sample file but left this for your convenience.
  # This takes 3 minutes on a 512mb file on my machine.
  # def test_large_files
  #   LOGGER.log "\n ###################### \n Test: Stream for large file \n ######################"
  #
  #   large_file_content = File.open('../File Server/large-file').read
  #   random_file_path = generate_file_name
  #
  #   ProxyFile.login 'Joe', 'puppies'
  #   file = ProxyFile.open random_file_path
  #   file.write large_file_content
  #   file.close
  #
  #   new_file_path = "../File Server/#{file.directory_data['file_server_name']}/#{file.directory_data['file_id']}"
  #   assert_equal File.open(new_file_path).read, large_file_content
  # end

  def test_auth
    exception = assert_raise(RuntimeError) {
      ProxyFile.login 'Joe', 'wrong password'
      file = ProxyFile.open 'lorem.html'
    }
    assert_equal 'The username and password did not match', exception.message
  end

  def test_directory_service
    LOGGER.log "\n ###################### \n Beginning tests for Directory service \n ######################"
    random_file_path = generate_file_name

    LOGGER.log("\n ###################### \n Test: Directory service; \n 2 users may own files which share the same user_path without writing over eachothers' file \n ######################")

    ProxyFile.login 'Joe', 'puppies'
    joes_file = ProxyFile.open random_file_path
    joes_file.write generate_file_content

    ProxyFile.login 'Alex', '42'
    alexs_file = ProxyFile.open random_file_path
    alexs_file.write generate_file_content
    assert_not_equal joes_file.read, alexs_file.read

    joes_file_path = "../File Server/#{joes_file.directory_data['file_server_name']}/#{joes_file.directory_data['file_id']}"
    alexs_file_path = "../File Server/#{alexs_file.directory_data['file_server_name']}/#{alexs_file.directory_data['file_id']}"
    assert_not_equal joes_file_path, alexs_file_path

    LOGGER.log("\n ###################### \n Test: Directory service; \n 3 new files created sequentially will be stored on different machines \n ######################")
    random_file_path = generate_file_name
    new_file = ProxyFile.open random_file_path
    new_file.write generate_file_content

    assert_not_equal alexs_file.directory_data['file_server_name'], joes_file.directory_data['file_server_name']
    assert_not_equal new_file.directory_data['file_server_name'], joes_file.directory_data['file_server_name']
    assert_not_equal new_file.directory_data['file_server_name'], alexs_file.directory_data['file_server_name']
  end

end