#!/usr/bin/ruby

require 'optparse'
require 'socket'
require 'digest/crc16_kermit.rb'

class Hexaruby
  Dat = [0,1,1,4,4,4,128,4]
  BTyp = [nil,"C","C","N",nil,"g","a128","N"]
  NTyp = [nil,"C","C","L",nil,"F","a128","L"]

  #Initialisierung: string ipv6adr, fixnum port
  def initialize(ipv6adr,port)
    @ipv6adr = ipv6adr
    @port = port
    @flags = 0x00
    open_socket
  end

  #Setzen der Ipv6adresse: string ipv6adr
  def set_ipv6adr(ipv6adr)
    if ipv6adr != nil then
      @ipv6adr = ipv6adr
    end
  end
  
  #Setzen des Port: fixnum port
  def set_port(port)
    if port != nil then
      @port = port
    end
  end  

  #Öffnen des UDP IPV6 Socket
  def open_socket
    @s = UDPSocket.new(Socket::AF_INET6)
  end

  #schleißen des Socket
  def close_socket
    @s.close
  end

  #Senden 
  def send_state(state)
    eid=0x01
    dat_typ=0x01
    write(eid,dat_typ,state)
  end

  def on
    write(0x01,0x01,0x01)
  end

  def off
    write(0x01,0x01,0x00)
  end

  def write(eid,dat_typ,value)
    pak_typ=0x04
    pak = ['HX0B',pak_typ,@flags,eid,dat_typ,value]
    string = pak.pack("a4C4"+NTyp[dat_typ])
    send(string)
  end

  def send(string)
    @s.send checksum(string),0,@ipv6adr,@port
  end

  def query(eid)
    pak_typ=2  
    pak = ['HX0B',pak_typ,@flags,eid]
    string = pak.pack("a4C3")
    send(string)
    antw = @s.recv(100)
    parst = parse(antw)
    puts "Paket Typ: "+parst[:pak_typ].to_s
    puts "Eid: "+parst[:eid].to_s
    puts "Daten Typ: "+parst[:dat_typ].to_s
    puts "Daten: "+parst[:data].to_s
  end

  def parse(antw) 
    data = {}
    len = 7+Dat[antw[7]]+2
    if antw[0..3] =='HX0B' then
      check = checksum(antw[0..len-2])
      if antw == check then
       data[:pak_typ] = antw[4]
       data[:eid] = antw[6]
       data[:dat_typ] = antw[7]
       if antw[7] <= 2 then
         data[:data] = antw[8]
       else
         roh = (antw[8..(Dat[antw[7]]+7)])
         if BTyp[antw[7]] != nil then
           y=roh.unpack(BTyp[antw[7]])
         else
           y=roh[0]
         end
         data[:data]=y 
      end  
    else
        puts 'Falsche Checksumme'
      end
    else
      puts 'Kein Hexabuspaket'
    end
   return data
  end

  def checksum(string)
    sum = Digest::CRC16KERMIT.hexdigest(string)
    y = [sum[0..1].to_i(16),sum[2..3].to_i(16)]
    return string+y.pack("CC")
  end
end