require 'socket'
a = UDPSocket.new(Socket::AF_INET6)
a.setsockopt(Socket::IPPROTO_IPV6, Socket::IPV6_JOIN_GROUP, IPAddr.new("ff02::1").hton+IPAddr.new("::0").hton)
a.bind("::",61616)
a.recv(100)
