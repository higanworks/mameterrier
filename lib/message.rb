# -*- coding: utf-8 -*-
# 13{送信時間(msec)}4{id}送信byte残り0埋め{padding}
# 1336955068764000100000...
class Message
  @@mon = Monitor.new
  @@message_table = {}

  attr_accessor :send_time, :id, :message

  class << self
    def parse(message)
      /(?<time>\d{13})(?<id>)\d{4}(?<padding>.*)/ =~ message
      ins = self.new
      ins.send_time = time
      ins.id = id
      ins.message = message
      ins
    end
  end

  def initialize(bytesize)
    set_message(bytesize)
  end

  def next_id
    last_id = 0
    @@mon.synchronize do 
      last_id = @@message_table.keys.sort{ |a, b| b <=> a }.first
      last_id ||= 0
      last_id += 1

      @@message_table[last_id] = ""
    end

    last_id
  end

  def set_message(bytesize)
    msec = Time.now.to_f.to_msec
    id = next_id
    @message = "#{msec}#{id}"

    @send_time = msec
    @id = id
    
    @message += "0" * bytesize - message.bytesize
  end
end
