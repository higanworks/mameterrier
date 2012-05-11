class WebSocketClient
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
