#!/usr/bin/ruby

require 'socket'

port=61616
#ipv6adr="aaaa::50:c4ff:fe04:81fd"
ipv6adr="aaaa::50:c4ff:fe04:8455"

s=UDPSocket.new(Socket::AF_INET6)
s.send "HEXABUS"+0x01.to_i.chr+0x00.to_i.chr+0x10.to_i.chr, 0, ipv6adr, port