#!/usr/bin/ruby

require 'optparse'
require 'socket'
require 'digest/crc16_kermit.rb'

class Hexaruby
  Dat = [0,1,1,4,4,4,128,4]
  ETyp = ["L","C","N","C","N","g"]
  DTyp = [nil,"N",nil,"N","g"]

  def initialize(ipv6adr,port)
    @ipv6adr = ipv6adr
    @port = port
    @flags = 0x00
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
    #@s.bind(nil,61616)
  end

  def close_socket
    @s.close
  end

  def send_state(state)
    eid=0x01
    dat_typ=0x01
    if state == 1 then
      value = 0x01
    elsif state == 0 then
      value = 0x00
    end
    write(eid,dat_typ,value)
  end

  def on
    write(0x01,0x01,0x01)
  end

  def off
    write(0x01,0x01,0x00)
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
    puts eid
    puts dat_typ
    puts value
    pak_typ=0x04
    pak = ['HX0B',pak_typ,@flags,eid,dat_typ,value]
    string = pak.pack("a4C3"+TYP[dat_typ])
    send_s(string)
  end

  def send_s(string)
    sum = checksum(string)
    @s.send string+to_chr(sum[0..1])+to_chr(sum[2..3]),0,@ipv6adr,@port
  end

  def query(eid)
    pak_typ=2  
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
         roh = (antw[8..(Dat[antw[7]]+7)])
         if DTyp[antw[7]] != nil then
           y=roh.unpack(DTyp[antw[7]])
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

  def to_chr(str)
    return  str.to_i(16).chr
  end

  def checksum(string)
    return Digest::CRC16KERMIT.hexdigest(string)
  end
end
