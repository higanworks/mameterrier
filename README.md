# CLIでBenchmark

## 使い方

100回を並列2で。(200リクエスト)

```
ruby ./mameterri.rb -n 100 -c 2 -u "ws://localhost:8080/jetty_websocket/ws/"
```

Scriptを渡す。

test.rb
```
Mameterrier.new("websocket", "ws://localhost:8080/jetty_websocket/ws/") do |cli|
  cli.connect(10, 10)
  cli.bloadcast("a" * 10)

  # Wait for receive message
  sleep 1
  
  cli.bloadcast("a" * 10)
  
  # Wait for receive message
  sleep 1
end
```

```
ruby ./mameterri.rb -f test.rb
```
