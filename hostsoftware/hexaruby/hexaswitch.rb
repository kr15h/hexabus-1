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
  opts.banner = 'Usage: hexaswitch.rb [options] on/off/power/status'
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
if ARGV.count = 1 then
  arg=ARGV[0].downcase
  if arg == 'power'
    options[:power] = 1
  elsif arg == 'on'
    options[:state] = 1
  elsif arg == 'off'
    options[:state] = 0
  elsif arg == 'status'
    options[:status] = 1
  end
elsif ARGV.count <= 3 then  
  if ARGV[0].downcase == "set"
    options[:eid] = ARGV[1]
    options[:value] = ARGV[2]
  elsif ARGV[0].downcase == "get"
    options[:eid] = ARGV[1]
    options[:value] = ARGV[2]
  end
elsif ARGV.count > 3 then
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

# Senden des Zustand nach neuem und altem Protokoll
if options[:old] then
  s=UDPSocket.new(Socket::AF_INET6)
  # Altes Protokoll, HEXABUS0100 + 11 für aus und 10 für an
  if options[:state] == 1 then
    string = 'HEXABUS'+0x01.to_i.chr+0x00.to_i.chr+0x10.to_i.chr
  elsif options[:state] == 0 then
    string = 'HEXABUS'+0x01.to_i.chr+0x00.to_i.chr+0x11.to_i.chr
  elsif options[:status] != nil or options[:power] then
    puts 'Im Alten Protokoll aktuell nicht m�glich'
    exit
  end
  s.send string, 0, ipv6adr, port
  s.close
else
  foo=Hexaruby.new(ipv6adr,port)
  if options[:state] != nil then 
    foo.send_state(options[:state])
  elsif options[:status] == 1 then
  foo.query("0x01")
  elsif options[:power] == 1 then
    foo.query("0x02")
  end
end
puts "Send!"
