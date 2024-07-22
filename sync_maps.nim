import netty

# @TODO

proc server*() =
  # listen for a connection on localhost port 1999
  var server = newReactor("127.0.0.1", 1999)
  echo "Listenting for UDP on 127.0.0.1:1999"
  # main loop
  while true:
    # must call tick to both read and write
    server.tick()
    # usually there are no new messages, but if there are
    for msg in server.messages:
      # print message data
      echo "GOT MESSAGE: ", msg.data
      # echo message back to the client
      server.send(msg.conn, "you said:" & msg.data)

proc client*() =
  # create connection
  var client = newReactor()
  # connect to server
  var c2s = client.connect("127.0.0.1", 1999)
  # send message on the connection
  client.send(c2s, "hi")
  # main loop
  while true:
    # must call tick to both read and write
    client.tick()
    # usually there are no new messages, but if there are
    for msg in client.messages:
      # print message data
      echo "GOT MESSAGE: ", msg.data
