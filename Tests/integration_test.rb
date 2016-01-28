require 'test/unit'
require '../File Server/file_server'
require '../Authentication Server/authentication_server'
require '../Client/proxy_file'

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
    ProxyFile.login 'Joe', 'puppies'
    file = ProxyFile.open 'lorem.html'
    content = file.read
    file.close
    assert_equal content, File.open('../File Server/lorem.html').read
  end

  def test_write
    ProxyFile.login 'Joe', 'puppies'
    file = ProxyFile.open 'new-file.html'
    file.write File.open('../File Server/lorem.html').read
    file.close

    assert_equal File.open('../File Server/lorem.html').read, File.open('../File Server/new-file.html').read
    File.delete '../File Server/new-file.html'
  end

  def test_auth
    exception = assert_raise(RuntimeError) {
      ProxyFile.login 'Joe', 'wrong password'
      file = ProxyFile.open 'lorem.html'
    }
    assert_equal 'The username and password did not match', exception.message
  end

end