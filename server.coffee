configuration = require "./config"
srcomp = require "./srcomp"

comp = new srcomp.SRComp configuration.SRCOMP
comp.state (state) ->
  console.log "Got state: #{state}"

console.log comp

