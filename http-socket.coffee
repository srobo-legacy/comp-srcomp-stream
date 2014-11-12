http = require 'http'

server = (comp) ->
  http.createServer (request, response) ->
    valid = true
    valid = false if request.url isnt '/'
    valid = false if request.method isnt 'GET'

    if not valid
      response.writeHead 404, 'Not Found', 'Content-Type': 'text/plain'
      response.end "Not a thing.\n", 'utf-8'
      return

    response.writeHead 200, 'OK', 'Content-Type': 'text/event-stream'

    sendEvent = (event) ->
      response.write "event: " + event.event + "\n", 'utf-8'
      response.write "data: " + JSON.stringify(event.data) + "\n\n", 'utf-8'

    stopListening = comp.events.onValue sendEvent

    for event in comp.seedRecords()
      sendEvent event

    response.on 'end', ->
      do stopListening

module.exports = server

