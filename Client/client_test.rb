require 'socket'
require './client_proxy.rb'

client_proxy = ClientProxy.new "Joe", "puppies"

puts client_proxy.open "small_lorem.html"
lorem = client_proxy.read
puts client_proxy.close
puts client_proxy.open "uploaded-lorem.html"
puts client_proxy.write lorem

client_proxy.disconnect