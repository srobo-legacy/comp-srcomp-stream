net = require 'net'

server = (comp) ->
  net.createServer (socket) ->
    sendEvent = (event) ->
      socket.write JSON.stringify(event) + "\n"

    stopListening = comp.events.onValue sendEvent

    for event in comp.seedRecords()
      sendEvent event

    socket.on 'end', ->
      do stopListening

module.exports = server

