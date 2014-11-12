rq = require 'request'

class SRComp
  constructor: (@base) ->
    @teams = {}
    setInterval (=> @queryState()), 10000
    do @queryState

  queryState: ->
    rq "#{@base}/state", (error, response, body) =>
      return if error
      return unless response.statusCode is 200
      newState = JSON.parse(body)['state']
      if newState isnt @savedState
        @savedState = newState
        console.log "Bump: #{newState}"
        do @reloadData

  reloadData: ->
    console.log "Reloading data"
    do @reloadTeams

  reloadTeams: ->
    rq "#{@base}/teams", (error, response, body) =>
      return if error
      return unless response.statusCode is 200
      @teams = JSON.parse(body)['teams']
      console.log @teams

module.exports =
  SRComp: SRComp

