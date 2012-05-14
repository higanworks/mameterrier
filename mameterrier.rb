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
require "rev"

require "core_ext"
require "web_socket_client"
require "comet_client"

options = {}

opt = OptionParser.new
opt.banner = "Usage: ruby test.rb [options]"

opt.separator "optios:"
opt.on("-c VAL", "--concurrency VAL") { |num| $concurrency = num }
opt.on("-n VAL", "--num VAL")         { |num| $num = num }
opt.on("-u VAL", "--url VAL")         { |url| $url = url }
opt.on("-d VAL", "--driver VAL")      { |driver| $driver = driver }
opt.on("-f VAL", "--file VAL")        { |file| $file = file }

# Set to default value
$num         ||= 1
$concurrency ||= 1
$url         ||= "ws://localhost:8080"
$driver      ||= "websocket"

opt.parse(ARGV)

$log = Logger.new(STDOUT)

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

  def connect(num, concurrency)
    close

    concurrency ||= 1
    
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

  def close
    @clients.map(&:close)
    @clients = []
  end
  
  def bloadcast(message)
    $log.info "try to bloadcast bytesize: #{message.bytesize}"

    start = Time.now.to_f

    @client_class.send(@url, message, @clients.first)

    $log.info "msg to #{@clients.size} clients. #{(Time.now.to_f - start).to_msec} ms"
  end
end

if ($file && File.file?($file))
  eval File.read($file)
else
  mame = Mameterrier.new($driver, $url)
  mame.connect($num, $concurrency)
  mame.bloadcast("a" * 10)
  mame.bloadcast("a" * 10)
  sleep 3
end



