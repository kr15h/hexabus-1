#require 'rubygems'
require 'socket'
#gem 'digest-crc', '= 0.3.9'
require 'digest/crc16_kermit.rb'

port=61616
ipv6adr="aaaa::50:c4ff:fe04:81fd"
#ipv6adr="aaaa::50:c4ff:fe04:8455"

string = 0x48.to_i.chr+0x58.to_i.chr+0x30.to_i.chr+0x42.to_i.chr+0x04.to_i.chr+0x00.to_i.chr+0x01.to_i.chr+0x01.to_i.chr+0x00.to_i.chr

checksum = Digest::CRC16KERMIT.hexdigest(string)

s=UDPSocket.new(Socket::AF_INET6)
s.send string+checksum[0..1].to_i(16).chr+checksum[2..3].to_i(16).chr, 0, ipv6adr, port
