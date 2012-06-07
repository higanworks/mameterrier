# -*- coding: utf-8 -*-
require "spec_helper"

describe Message do

  def freeze_time_now
    @now = Time.now
    Time.stub!(:now) { @now }
  end

  describe "id" do 
    it "必ずバイトサイズが6であること" do
      flg = true
      flg &= Message::IDGen.gen.bytesize == 6
      flg.should be_true
    end

    it "ほとんどユニークになること" do
      sporned = []
      3000.times { sporned << Message::IDGen.gen }
      sporned.size.should eq sporned.uniq.size
    end
  end

  describe "message body" do 
    # 1336955068764000010000...
    
    it "1-13文字がmsecを表していること" do
      freeze_time_now
      expect = @now.to_f.to_msec.to_s
      Message.new(50).to_s[0..12].should eq expect
    end

    it "14-19文字がidを表していること" do
      Message::IDGen.stub!(:gen) { 'abcdef' }
      Message.new(50).to_s[13..18].should eq 'abcdef'
    end

    it "引数に渡された数値分のbyte数があること" do
      Message.new(50).to_s.bytesize.should eq 50
    end
  end

  describe "parse" do
    it "パースできること" do
      given = "133908524451900000100000000000"

      mess = Message.parse(given)
      mess.send_time.should eq 1339085244519
      mess.id.should eq "000001"
      mess.message.should eq "133908524451900000100000000000"
    end
  end
end
