class TestHttp < Rev::HttpClient
  class << self
    def unconnected_request
      @unconnected_request ||= []
    end
  end
  
  def on_body_data(data)
  end

  def on_connect
    super
  end

  def on_request_complete
    self.class.unconnected_request.delete(self)
  end

  event_callback :on_request_complete
end

class CometClient
  @@loop = Rev::Loop.default
  @@in_loop = false
  @@mon = Monitor.new
  @@id_indicator = 0

  class << self
    def send(url, message, client=nil)
      uri = URI(url)
      m = TestHttp.connect(uri.host, uri.port)
      timer = Rev::TimerWatcher.new(2)
      timer.on_timer {
        m.request("POST", uri.path,
          body: URI.encode_www_form({ "message" => message }),
          head: { 'Content-Type' => 'application/x-www-form-urlencoded' }
          )
      }
      timer.attach(@@loop)
      m.attach(@@loop)
    end
  end
    
  def initialize(url)
    @loop = true
    
    @id = 0
    @@mon.synchronize do
      @@id_indicator += 1
      @id = @@id_indicator.to_i
    end

    uri = URI(url)
    
    req = lambda {
      if @loop
        m = TestHttp.connect(uri.host, uri.port)

        timer = Rev::TimerWatcher.new(1)
        id = @id
        timer.on_timer {
          TestHttp.unconnected_request << m
          m.request("GET", uri.path + "?user_id=#{id}")
        }
        m.attach(@@loop)
        timer.attach(@@loop)
        m.on_request_complete &req
      end
    }

    req.call

    unless @@in_loop
      @@in_loop = true
      Thread.new { @@loop.run } 
    end
  end

  def send(message)
  end

  def close
    @loop = false
  end

  def id
    @id
  end
end
