# CLIでBenchmark

## 使い方

### コマンドライン


100回を並列2で。(200リクエスト)

```
ruby ./mameterrier.rb -n 100 -c 2 -u "ws://localhost:8080/jetty_websocket/ws/"
```

comet

```
ruby ./mameterrier.rb -n 100 -c 2 -u "http://localhost:8080/jetty_websocket/comet" -d comet
```

### Scriptを渡す。


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

### Interactive
```
ruby ./mameterrier.rb -u <url> -i

* connect\( c) \<number of connections> : サーバーに接続
* send(s) \<number of clients> \<message byte size> : クライアントにメッセージを送信
* bloadcast(b) \<number of clients> : 全てのクライアントにメッセージを送信
