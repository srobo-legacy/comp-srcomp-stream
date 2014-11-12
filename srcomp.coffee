class SRComp
  constructor: (@base) ->
    console.log "Created srcomp @ #{@base}"

module.exports =
  SRComp: SRComp

