# -*- coding: utf-8 -*-
require "net/http"
require "uri"

class CometIdGenerator
  @@m = Monitor.new
  
  def self.gen
    ret = 0
    @@m.synchronize do 
      @indicator ||= 0
      @indicator += 1
      ret = @indicator.to_i
    end
    
    ret
  end
end

# =============== EventMachine ===================
# Request => 次のRequestでeventがwaitする><
# ================================================
#
# require "eventmachine"
# require "em-http"

# class CometClient
#   Thread.new { EventMachine.run }
#   @@connections = []

#   def self.send(url, message, clients, send_client=nil)
#     Net::HTTP.post_form(URI(url), { clin: clients, msg: message })
#   end

#   def initialize(url)
#     @reconnect = true
#     @id = CometIdGenerator.gen

#     on_complete = lambda {
#       if @reconnect
#         http = EM::HttpRequest.new(url, connect_timeout: 3600, inactivity_timeout: 3600).get(query: { user_id: @id })
#         http.callback {
#           timer = EM::Timer.new(1) {
#             on_complete.call
#             timer.cancel
#           }
#         }
#       end
#     }

#     on_complete.call
#   end

#   def close
#     @reconnect = false
#   end
# end

# =============== Celluloid ===================
# class MySocket
#   include Celluloid::IO

#   CR = '0x0d'
#   LF = '0x0a'

#   def initialize(url)
#     uri = URI(url)
#     @scoket = TCPSocket.from_ruby_socket(::TPCSocket.new(uri.host, uri.port))

#     header = ""
#     header << "GET #{uri.path} HTTP/1.1 #{CRLF}"
#     header << "Connection: close"
#     @socket.write(header)
#   end
# end



# =============== cool.io ===================
# そもそもhttp_clientが使えない ;; => ことなかった
# ===========================================
require "coolio"

class MyHttpClient < Coolio::HttpClient
  def initialize(socket, reconnect_proc)
    super(socket)
    @socket = socket
    @reconnect_proc = reconnect_proc
  end

  def on_body_data(data)
  end

  def on_request_complete
    super
  end

  def on_close
    super
    @reconnect_proc.call
  end

  def on_error
    super
  end
end

class CometClient
  @@loop = Coolio::Loop.new
  @@runned = false

  def self.send(url, message, clients, send_client=nil)
    Net::HTTP.post_form(URI(url), { clin: clients, msg: message })
  end

  def initialize(url)
    uri = URI(url)

    @reconnect = true

    connect = lambda {
      if @reconnect
        @c = MyHttpClient.connect(uri.host, uri.port, connect).attach(@@loop)
        @c.request('GET', uri.path)
      end
    }
    connect.call

    unless @@runned
      Thread.new { @@loop.run }
      @@runned = true
    end
  end

  def close
    @reconnect = false
    @c.close
  end
end


