class WebSocketClient
  class << self
    def send(url, message, client=nil)
      client.send(message)
    end
  end
  
  def initialize(url)
    @base = WebSocket.new(url)
  end

  def send(message)
    @base.send(message)
  end

  def close
    @base.close
  end
end
