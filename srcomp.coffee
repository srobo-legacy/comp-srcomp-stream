rq = require 'request'
_ = require 'underscore'
moment = require 'moment'
Bacon = require 'baconjs'
configuration = require './config'

class SRComp
  constructor: (@base) ->
    @events = new Bacon.Bus()
    @teams = {}
    @matches = []
    @currentDelay = 0
    @currentMatch = []
    @lastScoredMatch = null
    @koRounds = null
    do @queryConfig

  queryConfig: ->
    rq "#{@base}/config", (error, response, body) =>
      return if error
      return unless response.statusCode is 200
      @config = JSON.parse(body)['config']
      console.log @config
      do @queryState
      setInterval (=> do @sendPing), @config['ping_period'] * 1000
      setInterval (=> do @queryState), 500
      setInterval (=> do @updateCurrent), 2000

  queryState: ->
    rq "#{@base}/state", (error, response, body) =>
      return if error
      return unless response.statusCode is 200
      newState = JSON.parse(body)['state']
      if newState isnt @savedState
        @savedState = newState
        do @reloadData

  reloadData: ->
    console.log "Reloading data"
    do @reloadTeams
    do @reloadMatches
    do @reloadLastScoredMatch
    do @reloadKnockouts

  seedRecords: ->
    @seedTeamRecords().concat(@seedMatchRecord())
                      .concat(@seedScoredMatchRecord())
                      .concat(@seedKnockoutsRecord())
                      .concat(@seedDelayRecord())

  seedTeamRecords: ->
    for team, record of @teams
      event: 'team'
      data: record

  seedDelayRecord: ->
    [{event: 'delay_value', data: @currentDelay}]

  seedMatchRecord: ->
    [{event: 'match', data: @currentMatch}]

  seedScoredMatchRecord: ->
    return [] if not @lastScoredMatch?
    [{event: 'last-scored-match', data: @lastScoredMatch}]

  seedKnockoutsRecord: ->
    return [] if not @koRounds?
    [{event: 'knockouts', data: @koRounds}]

  txTeamRecord: (tla, record) ->
    @events.push
      event: 'team'
      data: record

  reloadTeams: ->
    rq "#{@base}/teams", (error, response, body) =>
      return if error
      return unless response.statusCode is 200
      newTeams = JSON.parse(body)['teams']
      if not _.isEqual(@teams, newTeams)
        # Diffs 1: deleted teams
        for key of _.difference(_.keys(@teams), _.keys(newTeams))
          @txTeamRecord key, null
        # Diffs 2: actual differences
        for key, record of newTeams
          if not _.isEqual(record, @teams[key])
            @txTeamRecord key, record
        @teams = newTeams

  reloadMatches: ->
    rq "#{@base}/matches", (error, response, body) =>
      return if error
      return unless response.statusCode is 200
      matches = JSON.parse(body)['matches']
      if not _.isEqual(@matches, matches)
        @matches = matches
        do @updateCurrent

  reloadLastScoredMatch: ->
    rq "#{@base}/matches/last_scored", (error, response, body) =>
      return if error
      return unless response.statusCode is 200
      lastScoredMatch = JSON.parse(body)['last_scored']
      if not _.isEqual(@lastScoredMatch, lastScoredMatch)
        @lastScoredMatch = lastScoredMatch
        @events.push
          event: 'last-scored-match'
          data: @lastScoredMatch

  updateCurrent: ->
    rq "#{@base}/current", (error, response, body) =>
      return if error
      return unless response.statusCode is 200
      currentInfo = JSON.parse(body)
      newCurrentMatch = currentInfo['matches']
      if not _.isEqual(newCurrentMatch, @currentMatch)
        @currentMatch = newCurrentMatch
        @events.push
          event: 'match'
          data: @currentMatch
      newCurrentDelay = currentInfo['delay']
      if not _.isEqual(newCurrentDelay, @currentDelay)
        @currentDelay = newCurrentDelay
        @events.push
          event: 'delay_value'
          data: @currentDelay

  sendPing: ->
    @events.push
      event: 'ping'
      data: {}

  reloadKnockouts: ->
    rq "#{@base}/knockout", (error, response, body) =>
      return if error
      return unless response.statusCode is 200
      newKORounds = JSON.parse(body)['rounds']
      if not _.isEqual(@koRounds, newKORounds)
        @koRounds = newKORounds
        @events.push
          event: 'knockouts'
          data: @koRounds

module.exports =
  SRComp: SRComp
