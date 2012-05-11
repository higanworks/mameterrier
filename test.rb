Mameterrier.new("websocket", "ws://localhost:8080/jetty_websocket/ws/") do |cli|
  cli.connect(10, 10)
  cli.bloadcast("a" * 10)
  
  sleep 1
  
  cli.bloadcast("a" * 10)
  
  sleep 1
end




