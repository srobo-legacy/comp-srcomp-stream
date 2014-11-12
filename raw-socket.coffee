net = require 'net'

server = (comp) ->
  net.createServer (socket) ->
    sendEvent = (event) ->
      try
        socket.write JSON.stringify(event) + "\n"
      catch error
        do stopListening

    stopListening = comp.events.onValue sendEvent

    for event in comp.seedRecords()
      sendEvent event

    socket.on 'end', ->
      do stopListening

module.exports = server

