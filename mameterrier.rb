# -*- coding: utf-8 -*-
$:.unshift File.expand_path("../", __FILE__)
$:.unshift File.expand_path("../lib", __FILE__)

require "bundler"
Bundler.setup

require "optparse"
require "web_socket"
require "monitor"
require "logger"
require "benchmark"

require "core_ext"
require "web_socket_client"
require "comet_client"
require "message"

# 初期値設定
$log         ||= Logger.new(STDOUT)
$num         ||= 1
$concurrency ||= 1
$url         ||= "ws://localhost:8080"
$driver      ||= "websocket"

Thread.abort_on_exception = true

class Mameterrier
  # まめてりあ

  def initialize(driver, url)
    @url = url
    @clients = []
    
    case driver
    when "websocket"
      @client_class = WebSocketClient
    when "comet"
      @client_class = CometClient
    else
      throw "Unregocnized client #{client_name}."
    end

    yield self if block_given?
  end

  def open(url)
    @client_class.new(url)
  end

  def connect(num, concurrency=1)
    close

    start = Time.now.to_f
    
    $log.info "try to open #{num} connection. cuncurrency: #{concurrency}"

    threads = []

    concurrency.to_i.times do
      threads << Thread.new do
        num.to_i.times do
          begin
            @clients << self.open(@url)
          rescue WebSocket::Error
            $log.error "error occured"
          end
        end
      end
    end
    
    threads.map(&:join)

    $log.info "open #{@clients.size} connection. #{(Time.now.to_f - start).to_msec} ms"
  end
  alias :c :connect

  def close
    @clients.map(&:close)
    @clients = []
  end
  
  # Send message to clients from connected clients
  def send(clients=1, bytesize=50)
    $log.info "Send message bytesize: #{bytesize}"

    message = Message.new(bytesize).to_s

    start = Time.now.to_f
    
    @client_class.send(@url, message, clients, @clients.first)
    
    $log.info "msg to #{clients} clients. #{(Time.now.to_f - start).to_msec} ms"
  end
  alias :s :send
  
  # Send message to all clients
  def bloadcast(bytesize=50)
    send(0, bytesize)
  end
  alias :b :bloadcast
end
