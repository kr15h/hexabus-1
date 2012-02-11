#!/usr/bin/ruby

require 'optparse'
require 'socket'
require 'digest/crc16_kermit.rb'

port=61616
addr=["aaaa::50:c4ff:fe04:81fd","aaaa::50:c4ff:fe04:8455"]
options = {}

optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: hexaswitch.rb [options] on/off'
  opts.separator ' '
  
  opts.on_tail('-h', '--help', 'Bitte Parameter angeben') do
    puts opts
    exit
  end

  options[:verb] = false
  opts.on('-v', '--verbose', 'Verbose Mode') do
    options[:verb] = true
  end

  options[:old] = false
  opts.on('-o', '--old', 'Old Hexabus Protokoll') do
    options[:old] = true
  end

  options[:ip] = nil
  opts.on('-i ', '--ip-addr ', 'IPv6 address of the plug') do |i|
    options[:ip] = i
  end 

  options[:num] = 0
  opts.on('-n ', '--number ', 'If address in script number in array') do |z|
    options[:num] = z.to_i
  end
end

optparse.parse!

if ARGV.count == 1 then
  options[:state] = ARGV[0].downcase
elsif ARGV.count > 1 then
  puts 'Zu viele Parameter'
  exit
end

if options[:ip] != nil then
  ipv6adr=options[:ip]
elsif options[:num] > 0 then
  ipv6adr=addr[options[:num]-1]
else
  puts "No Adress"
  exit
end

if options[:state] == 'on' then
  options[:hex] = "0x01"
elsif options[:state] == 'off' then
  options[:hex] = "0x00"
else
  puts 'on/off'
  exit
end

puts options[:hex]

s=UDPSocket.new(Socket::AF_INET6)
if options[:old] then
  s.send 'HEXABUS'+0x01.to_i.chr+0x00.to_i.chr+0x10.to_i.chr, 0, ipv6adr, port
  puts 'old'
else
  string = 0x48.to_i.chr+0x58.to_i.chr+0x30.to_i.chr+0x42.to_i.chr+0x04.to_i.chr+0x00.to_i.chr+0x01.to_i.chr+0x01.to_i.chr+options[:hex].to_i(16).chr
  checksum = Digest::CRC16KERMIT.hexdigest(string)
  s.send string+checksum[0..1].to_i(16).chr+checksum[2..3].to_i(16).chr, 0, ipv6adr, port
end
s.close
puts "Send!"
