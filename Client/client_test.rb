require 'socket'
require './client_proxy.rb'

client_proxy = ClientProxy.new "Joe", "puppies"

puts client_proxy.open "small_lorem.html"
puts client_proxy.read
puts client_proxy.close
puts client_proxy.open "new.html"
puts client_proxy.write "Hello 4\n I am a dist file system!!11!1111\nlol!\nCREAM"

# client_proxy.disconnect