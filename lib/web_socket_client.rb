# -*- coding: utf-8 -*-
require "libwebsocket"
require "cool.io"

# 途中
class MyWebSocket < Cool.io::TCPSocket
  def on_connect
  end

  def on_close
  end

  def on_read
  end

  def on_connect_failed
  end
end
# --

class WebSocketClient
  class << self
    def send(url, message, clients, send_client=nil)
      send_client.send("#{clients.to_i},#{message}")
    end
  end

  def on_read(data)
    $log.debug data
  end
  
  def initialize(url)
    @base = WebSocket.new(url)
    @continue = true
    Thread.new do
      while @continue && (line = @base.receive)
        method(:on_read).call(line)
      end
    end
  end

  def send(message)
    @base.send(message)
  end

  def close
    @continue = false
    @base.close
  end
end
