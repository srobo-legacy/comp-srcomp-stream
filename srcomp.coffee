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

_formatMatches = (matches) ->
  for match in matches
    arena: match.arena
    num: match.num
    type: match.type
    teams: match.teams
    start: moment(match.start_time)
    end: moment(match.end_time)
    begin: moment(match.start_time).add(configuration.MATCH_START_OFFSET,
                                        's')

_calculateCurrentMatch = (matches) ->
  now = moment()
  active = (match) ->
    match.start.isBefore(now) and match.end.isAfter(now)
  match for match in matches when active(match)

class SRComp
  constructor: (@base) ->
    @events = new Bacon.Bus()
    @teams = {}
    @matches = []
    @currentMatch = []
    setInterval (=> do @queryState), 10000
    setInterval (=> do @updateCurrentMatch), 2000
    do @queryState

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

  seedTeamRecords: ->
    for team, record of @teams
      event: 'team'
      data: record

  seedMatchRecord: ->
    [{event: 'match', data: @currentMatch}]

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
      newMatches = _formatMatches(JSON.parse(body)['matches'])
      if not _.isEqual(@matches, newMatches)
        @matches = newMatches
        do @updateCurrentMatch

  updateCurrentMatch: ->
    newCurrent = _calculateCurrentMatch(@matches)
    if not _.isEqual(newCurrent, @currentMatch)
      @currentMatch = newCurrent
      @events.push
        event: 'match'
        data: @currentMatch

module.exports =
  SRComp: SRComp

