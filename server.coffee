configuration = require "./config"
srcomp = require "./srcomp"
Bacon = require 'baconjs'

raw = require './raw-socket'
sse = require './http-socket'

comp = new srcomp.SRComp configuration.SRCOMP

comp.events.onValue (event) ->
  console.log event

raw(comp).listen(configuration.SOCKET_PORT, '::')
sse(comp).listen(configuration.WEB_PORT, '::')

