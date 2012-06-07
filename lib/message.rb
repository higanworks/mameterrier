# -*- coding: utf-8 -*-
# 13{送信時間(msec)}6{id}送信byte残り0埋め{padding}
# 13369550687640000010000...
class Message
  class IDGen
    STR = ('a'..'z').to_a + ('0'..'9').to_a
    
    def self.gen
      # おそらくたまにかぶる
      STR.sort_by{ rand }[0..5].join
    end
  end

  attr_accessor :send_time, :id, :message

  class << self
    def parse(message)
      /(?<time>\d{13})(?<id>\d{6})(?<padding>.*)/ =~ message
      ins = self.new
      ins.send_time = time.to_i
      ins.id = id
      ins.message = message
      ins
    end
  end

  def initialize(bytesize=0)
    set_message(bytesize) if bytesize > 0
  end

  def set_message(bytesize)
    msec = Time.now.to_f.to_msec
    id = IDGen.gen
    @message = "#{msec}#{id}"

    @send_time = msec
    @id = id
    
    @message += "0" * (bytesize - message.bytesize)
    @message
  end

  def to_s
    @message
  end
end
