#!/usr/bin/ruby

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

class Hexaruby
  Dat = [0,1,1,4,4,4,128,4]
  def initialize(ipv6adr,port)
    @ipv6adr = ipv6adr
    @port = port
    @flags = to_chr("0x00")
    open_socket
  end

  def set_ipv6adr(ipv6adr)
    if ipv6adr != nil then
      @ipv6adr = ipv6adr
    end
  end
  
  def set_port(port)
    if port != nil then
      @port = port
    end
  end  

  def open_socket
    @s = UDPSocket.new(Socket::AF_INET6)
    @s.bind("aaaa::1",61616)
  end
  def close_socket
    @s.close
  end
  def send_state(state)
    eid=to_chr("0x01")
    dat_typ=to_chr("0x01")
    if state.downcase == 'on' then
      value = to_chr("0x01")
    elsif state.downcase == 'off' then
      value = to_chr("0x00")
    end
    write(eid,dat_typ,value)
  end

  def send(pak_typ,eid,dat_typ,value)
  if pak_typ == 0x04 then 
    write(eid,dat_typ,value)
  end
  if pak_typ == 0x03 then
    query(eid)
  end
  end

  def write(eid,dat_typ,value)
    pak_typ=to_chr("0x04")
    string = 'HX0B' + pak_typ + @flags + eid + dat_typ + value
    send_s(string)
  end

  def send_s(string)
    sum = checksum(string)
    @s.send string+to_chr(sum[0..1])+to_chr(sum[2..3]),0,@ipv6adr,@port
  end

  def query(eid)
    pak_typ=to_chr("0x02")  
    string = 'HX0B'+pak_typ+@flags+to_chr(eid)
    send_s(string)
    antw = @s.recv(100)
    puts parse(antw)
  end

  def parse(antw) 
    data = {}
    len = 7+Dat[antw[7]]+2
    if antw[0..3] =='HX0B' then
      sum = checksum(antw[0..len-2])
      check = to_chr(sum[0..1])+to_chr(sum[2..3])
      if antw[len-1..len] == check then
       data[:pak_typ] = antw[4]
       data[:eid] = antw[6]
       data[:dat_typ] = antw[7]
       if antw[7] <= 2 then
         data[:data] = antw[8]
       else
         data[:data] = (antw[8..(Dat[antw[7]]+7)])
       end  
    else
        puts 'Falsche Checksumme'
      end
    else
      puts 'Kein Hexabuspaket'
    end
   return data
  end

  def to_chr(str)
    return  str.to_i(16).chr
  end

  def checksum(string)
    return Digest::CRC16KERMIT.hexdigest(string)
  end
end

# Senden des Zustand nach neuem und altem Protokoll
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
