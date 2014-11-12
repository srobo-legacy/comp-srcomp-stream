configuration = require "./config"
srcomp = require "./srcomp"
Bacon = require 'baconjs'

comp = new srcomp.SRComp configuration.SRCOMP

comp.events.onValue (event) ->
  console.log event

