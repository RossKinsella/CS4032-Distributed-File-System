require 'test/unit'
require '../File Server/file_server'
require '../Authentication Server/authentication_server'
require '../Client/client_proxy'

class IntegrationTest < Test::Unit::TestCase

  Thread.new do
    begin
      FileServer.new
    rescue => e
      LOGGER.log 'File Server:' << e
    end
  end
  Thread.new do
    begin
      AuthServer.new
    rescue => e
      LOGGER.log 'Auth Server' << e
    end
  end

  LOGGER.log 'waiting to allow services to boot...'
  sleep 4 # Let the servers boot up

  def test_read
    client = ClientProxy.new 'Joe', 'puppies'
    client.open 'lorem.html'
    file = client.read
    client.close
    assert_equal file, File.open('../File Server/lorem.html').read
  end

  def test_write
    client = ClientProxy.new 'Joe', 'puppies'
    client.open 'new-file.html'
    client.write File.open('../File Server/lorem.html').read
    client.close

    assert_equal File.open('../File Server/lorem.html').read, File.open('../File Server/new-file.html').read
    File.delete '../File Server/new-file.html'
  end

  def test_auth
    client = ClientProxy.new 'Joe', 'wrong password'
    response = client.open 'lorem.html'
    assert_equal response.to_s, 'The username and password did not match'
  end

end