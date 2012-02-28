#!/usr/bin/ruby

require 'hexabus.rb'
require 'optparse'
require 'socket'
require 'digest/crc16_kermit.rb'
# Gundlegende Defenitionen
port=61616
# Array mit Adressen zum vereinfachten Zugriff via -n
addr=["aaaa::50:c4ff:fe04:81fd","aaaa::50:c4ff:fe04:8455"]
options = {}
hexapack = {}
# Parser für die Komandozeilenparameter
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
# Parsen der Parameter und entfernen aus ARGV
optparse.parse!

# Prüfen ob der Zusatnds Parameter vorhanden ist, wenn nicht Fehler ausgeben.
if ARGV.count == 1 then
  options[:state] = ARGV[0].downcase
elsif ARGV.count > 1 then
  puts 'Zu viele Parameter'
  exit
end

# Überprüfung über welchen Parameter die Adresse kommt
if options[:ip] != nil then
  ipv6adr=options[:ip]
elsif options[:num] > 0 then
  ipv6adr=addr[options[:num]-1]
else
  puts "No Adress"
  exit
end

if options[:old] then
  s=UDPSocket.new(Socket::AF_INET6)
  # Altes Protokoll, HEXABUS0100 + 11 für aus und 10 für an
  if options[:state].downcase == "on" then
    string = 'HEXABUS'+0x01.to_i.chr+0x00.to_i.chr+0x10.to_i.chr
  elsif options[:state].downcase == "off" then
    string = 'HEXABUS'+0x01.to_i.chr+0x00.to_i.chr+0x11.to_i.chr
  end
  s.send string, 0, ipv6adr, port
  s.close
else
  foo=Hexaruby.new(ipv6adr,port)
  foo.send_state(options[:state])
  foo.query("0x01")
  foo.query("0x02")
end
puts "Send!"
