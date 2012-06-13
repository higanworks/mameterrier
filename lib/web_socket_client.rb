# -*- coding: utf-8 -*-
require "cool.io"
require "openssl"

# 途中

class WSProtocol
  def initialize(url)
    @url = url
  end

  def generate_masking_key_array
    [rand(0..255), rand(0..255), rand(0..255), rand(0..255)]
  end
  
  def generate_key
    [OpenSSL::Random.random_bytes(16)].pack('m').chop
  end

  def mask(data, mask)
    payload = data.bytes.to_a

    payload.each_with_index do |p, i|
      j = i % 4
      payload[i] = p ^ mask[j]
    end

    return payload.map(&:chr).join
  end

  def handshake_header
    uri = URI(@url)

    packet = ""
    packet << "GET #{uri.path} HTTP/1.1\r\n"
    packet << "Host: #{uri.host}:#{uri.port}\r\n"
    packet << "Upgrade: websocket\r\n"
    packet << "Connection: Upgrade#\r\n"
    packet << "Sec-WebSocket-Key: #{self.generate_key}\r\n"
    packet << "Origin: http://#{uri.host}:#{uri.port}\r\n"
    packet << "Sec-WebSocket-Version: 13\r\n\r\n"
    
    packet
  end

  def frame(data)
    frame = ''
    frame.force_encoding("ASCII-8BIT")
    frame << 0b10000001 #=> fin[1]recv1-3[000]opcode(text)[0001]

    p "==========opcode"
    p frame

    # ========= データサイズ
    len = data.size

    if len < 126
      frame << (len | 0b10000000)
    elsif len <= 65536
      frame << 0b11111110
      frame << [len].pack("n")
    else
      frame << 0b11111111
      frame << [len >> 32, len & 0xFFFFFFFF].pack("NN")
    end

    p "==========datasize"
    p frame
    
    # ========= マスク
    m_array = generate_masking_key_array
    frame << m_array.pack("C*")

    p "==========masking key"
    p frame

    masked_data = mask(data, m_array)

    frame << masked_data
  end

  def send(message)
    @socket.write(@proto.frame(message))
    @socket.flush
  end
end

# --- cool.io
class MyWebSocket < Cool.io::TCPSocket
  def initialize(io, url)
    super(io)
    @socket = io
    @proto = WSProtocol.new(url)
  end
  
  def on_connect
    @socket.write(@proto.handshake_header)
    @socket.flush
  end

  def on_read(data)
    if @handshaked
      data
    else
      lines = data.split("\r\n")
      status_line = lines.shift
      
      /(\w*)\s(?<status>\d*).*/ =~ status_line

      if status.to_i == 101
        @handshaked = true
      else
        p "refused?"
      end
    end
  end

  def send(message)
    @socket.write(@proto.frame(message))
    @socket.flush
  end

  def on_close
    p "close"
  end

  def on_connect_failed
    p "connection error"
  end
end


# ----- celluloid
# class MyWebSocket
#   include Celluloid::IO

#   def initialize(host, port)
#     p "connect"
#     @socket = TCPSocket.from_ruby_socket(::TCPSocket.new(host, port))
#   end

#   def echo
#     p "aaa"
#     actor = Celluloid.current_actor
#     p "aaaa"
#   end
  
  
  
#   # def on_connect
#   #   p "connected"
#   # end

#   # def on_close
#   # end

#   # def on_read
#   # end

#   # def on_connect_failed
#   # end
# end
# --

class WebSocketClient
  @@event_loop = Cool.io::Loop.new
  @@runned = false

  class << self
    def send(url, message, clients, send_client=nil)
      send_client.send("#{clients.to_i},#{message}")
    end
  end

  def on_connect(data)
    $log.debug data
  end
  
  def initialize(url)
    uri = URI(url)

    @base = MyWebSocket.connect(uri.host, uri.port, url)
    @base.attach(@@event_loop)

    unless @@runned
      Thread.new { @@event_loop.run }
      @@runned = true 
    end
    
    # @base = MyWebSocket.new(uri.host, uri.port)
    # @base.wait_readable
    # @base = WebSocket.new(url)
    # @continue = true
    # Thread.new do
    #   while @continue && (line = @base.receive)
    #     method(:on_read).call(line)
    #   end
    # end
  end

  def send(message)
    @base.send(message)
  end

  def close
    @continue = false
    @base.close
  end
end


# class WebSocketClient
#   class << self
#     def send(url, message, clients, send_client=nil)
#       send_client.send("#{clients.to_i},#{message}")
#     end
#   end

#   def on_read(data)
#     $log.debug data
#   end
  
#   def initialize(url)
#     @base = WebSocket.new(url)
#     # @continue = true
#     # Thread.new do
#     #   while @continue && (line = @base.receive)
#     #     method(:on_read).call(line)
#     #   end
#     # end
#   end

#   def send(message)
#     @base.send(message)
#   end

#   def close
#     @continue = false
#     @base.close
#   end
# end
