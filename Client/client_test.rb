require 'socket'
require './client_proxy.rb'

client_proxy = ClientProxy.new

puts client_proxy.open "lorem.html"
puts client_proxy.read

client_proxy.disconnect