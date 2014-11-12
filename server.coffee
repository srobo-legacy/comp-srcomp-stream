configuration = require "./config"
srcomp = require "./srcomp"
Bacon = require 'baconjs'

raw = require './raw-socket'

comp = new srcomp.SRComp configuration.SRCOMP

comp.events.onValue (event) ->
  console.log event

raw(comp).listen(5000)

