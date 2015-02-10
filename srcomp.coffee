rq = require 'request'
_ = require 'underscore'
moment = require 'moment'
Bacon = require 'baconjs'
configuration = require './config'

_formatTeams = (teams) ->
  result = {}
  for team, data of teams
    result[team] =
      tla: team
      name: data.name
      game_points: data.scores.game
      league_points: data.scores.league
  return result

_calculateCurrentMatch = (matches) ->
  now = moment()
  active = (match) ->
    start = moment(match.times.period.start)
    end = moment(match.times.period.end)
    start.isBefore(now) and end.isAfter(now)
  match for match in matches when active(match)

class SRComp
  constructor: (@base) ->
    @events = new Bacon.Bus()
    @teams = {}
    @matches = []
    @currentMatch = []
    @lastScoredMatch = null
    @knockouts = []
    do @queryConfig

  queryConfig: ->
    rq "#{@base}/config", (error, response, body) =>
      return if error
      return unless response.statusCode is 200
      @config = JSON.parse(body)['config']
      console.log @config
      do @queryState
      setInterval (=> do @queryState), 10000
      setInterval (=> do @updateCurrentMatch), 2000

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

  seedRecords: ->
    @seedTeamRecords().concat(@seedMatchRecord())
                      .concat(@seedScoredMatchRecord())
                      .concat(@seedKnockoutsRecord())

  seedTeamRecords: ->
    for team, record of @teams
      event: 'team'
      data: record

  seedMatchRecord: ->
    [{event: 'match', data: @currentMatch}]

  seedScoredMatchRecord: ->
    return [] if not @lastScoredMatch?
    [{event: 'scored-to', data: @lastScoredMatch}]

  seedKnockoutsRecord: ->
    [{event: 'knockouts', data: @knockouts}]

  txTeamRecord: (tla, record) ->
    @events.push
      event: 'team'
      data: record

  reloadTeams: ->
    rq "#{@base}/teams", (error, response, body) =>
      return if error
      return unless response.statusCode is 200
      newTeams = _formatTeams(JSON.parse(body)['teams'])
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
        do @updateLastScored
        do @updateCurrentMatch
        do @updateKnockouts

  updateCurrentMatch: ->
    newCurrent = _calculateCurrentMatch(@matches)
    if not _.isEqual(newCurrent, @currentMatch)
      @currentMatch = newCurrent
      @events.push
        event: 'match'
        data: @currentMatch

  updateLastScored: ->
    scoredUpTo = null
    for match in @matches
      break unless match.scores?
      scoredUpTo = match['num']
    if scoredUpTo isnt @lastScoredMatch
      @lastScoredMatch = scoredUpTo
      @events.push
        event: 'scored-to'
        data: @lastScoredMatch

  updateKnockouts: ->
    knockouts = (match for match in @matches when match.type is 'knockout')
    if not _.isEqual(knockouts, @knockouts)
      @knockouts = knockouts
      @events.push
        event: 'knockouts'
        data: @knockouts

module.exports =
  SRComp: SRComp
