rq = require 'request'

class SRComp
  constructor: (@base) ->
    console.log "Created srcomp @ #{@base}"

  state: (callback) ->
    rq "#{@base}/state", (error, response, body) ->
      return if error
      return unless response.statusCode is 200
      callback(JSON.parse(body)['state'])

module.exports =
  SRComp: SRComp

