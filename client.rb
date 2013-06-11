require 'eventmachine'
require 'em-websocket-client'
require 'json'

EM.run do
  conn = EventMachine::WebSocketClient.connect("ws://metalive.tryphon.eu:8081/")

  conn.errback do |e|
    puts "Got error: #{e}"
  end

  conn.stream do |msg|
    event = JSON.parse(msg)
    puts event.inspect
  end

  conn.disconnect do
    puts "gone"
    EM::stop_event_loop
  end
end
