#!/bin/ruby1.9.1

require 'socket'

port=61616
ipv6adr="aaaa::50:c4ff:fe04:81fd"

s=UDPSocket.new(Socket::AF_INET6)
s.send "HEXABUS"+0x01.to_i.chr+0x00.to_i.chr+0x11.to_i.chr, 0, ipv6adr, port
