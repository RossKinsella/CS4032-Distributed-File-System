require 'test/unit'
require '../File Server/file_server'
require '../Authentication Server/authentication_server'
require '../Directory Server/directory_server'
require '../Client/proxy_file'

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
    # Set up
    directory_db = File.open '../Directory Server/database.json'
    db_content = directory_db.read
    directory_db.close

    # Test
    ProxyFile.login 'Joe', 'puppies'
    file = ProxyFile.open 'new-file.html'
    file.write File.open('../File Server/Thor/1').read
    file.close
    directory_data = file.directory_data
    file_path = "../File Server/#{directory_data['file_server_name']}/#{directory_data['file_id']}"
    assert_equal File.open('../File Server/Thor/1').read, File.open(file_path).read

    # Clean up
    File.delete file_path
    directory_db = File.open '../Directory Server/database.json', 'w'
    directory_db.write db_content
    directory_db.close
  end

  def test_auth
    exception = assert_raise(RuntimeError) {
      ProxyFile.login 'Joe', 'wrong password'
      file = ProxyFile.open 'lorem.html'
    }
    assert_equal 'The username and password did not match', exception.message
  end

end