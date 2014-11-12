rq = require 'request'
_ = require 'underscore'
moment = require 'moment'

_format_teams = (teams) ->
  result = {}
  for team, data of teams
    result[team] =
      name: data.name
      game_points: data.scores.game
      league_points: data.scores.league
  return result

_format_matches = (matches) ->
  for match in matches
    arena: match.arena
    num: match.num
    type: match.type
    teams: match.teams
    start: moment(match.start_time)
    end: moment(match.end_time)

_calculateCurrentMatch = (matches) ->
  now = moment()
  for match in matches
    if match.start.isBefore(now) and match.end.isAfter(now)
      return match
  return null

class SRComp
  constructor: (@base) ->
    @teams = {}
    @matches = []
    @currentMatch = null
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
        console.log "Bump: #{newState}"
        do @reloadData

  reloadData: ->
    console.log "Reloading data"
    do @reloadTeams
    do @reloadMatches

  txTeamRecord: (tla, record) ->
    console.log tla, record

  reloadTeams: ->
    rq "#{@base}/teams", (error, response, body) =>
      return if error
      return unless response.statusCode is 200
      newTeams = _format_teams(JSON.parse(body)['teams'])
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
      newMatches = _format_matches(JSON.parse(body)['matches'])
      if not _.isEqual(@matches, newMatches)
        @matches = newMatches
        do @updateCurrentMatch

  updateCurrentMatch: ->
    newCurrent = _calculateCurrentMatch(@matches)
    if not _.isEqual(newCurrent, @currentMatch)
      @currentMatch = newCurrent
      console.log newCurrent

module.exports =
  SRComp: SRComp

