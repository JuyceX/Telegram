-- Get infos about football's European leagues (such as games' results, planned games, ranks etc.) directly from Telegram!
-- Infos provided by football-data.org (thanks to his creator, Daniel Freitag)
-- Brought to you by @JuyceX
-- Have fun! :)

local function get_suffix(num)
    local suffix = ''
    num = tonumber(num)
    if num == 1 then
        suffix = 'st'
    elseif num == 2 then
        suffix = 'nd'
    elseif num == 3 then
        suffix = 'rd'
    else
        suffix = 'th'
    end
    
    return suffix
end

local function get_curr_date()
      return  os.date("%Y-%m-%d")
end

local function process_url(_url)
  local respbody = {}
  local body, code, headers, status = http.request {
        method = "GET",
        url = _url,
        headers = {["X-Auth-Token"] = "HERE_YOUR_AUTH_TOKEN"}, -- You can obtain one registering here: http://api.football-data.org/register
        sink = ltn12.sink.table(respbody)
  }
 
  local body = ''
  for k, v in pairs (respbody) do
        body = body..v
  end
  
  if code ~= 200 then return nil end
  local data = json:decode(body)
  if not data then
    print("HTTP Error")
    return nil
  end
  
  return data
end

local function get_leagues()
  local data = process_url('http://api.football-data.org/v1/soccerseasons/')
  
  local leagues = ''
  local i=1
  while i<#data do
        local l_infos_t = data[i]
        leagues = leagues.."LEAGUE NAME: "..l_infos_t.caption.."\n"
        leagues = leagues.."TEAMS: "..l_infos_t.numberOfTeams.."\n"
        leagues = leagues.."TOTAL MATCHES: "..l_infos_t.numberOfGames.."\n"
        leagues = leagues.."[CODE: "..l_infos_t.league.."]\n\n\n"
        i=i+1
  end
  
  return leagues
end

local function get_league_url(l_code)
  local data = process_url('http://api.football-data.org/v1/soccerseasons/')
  if data == nil then return end
  
  local url = nil
  for i=1, #data do
     if data[i].league == l_code then
         url = data[i]._links.self.href
         break
     end
  end
  
  return url
end

local function get_league_table(url)
    local data = process_url(url)
    if data == nil then return end
    local l_table_t = data.standing
    
    local l_table = ''
    for i=1, #l_table_t do
        l_table = l_table.."<"..l_table_t[i].position.."> "..l_table_t[i].teamName.." ("..l_table_t[i].points..")\n"
        l_table = l_table.."{WON: "..l_table_t[i].wins..", DRAWN: "..l_table_t[i].draws..", MISSED: "..l_table_t[i].losses.."}\n"
        l_table = l_table.."[GOALS SCORED: "..l_table_t[i].goals..", GOALS AGAINST: "..l_table_t[i].goalsAgainst.."]\n\n\n"
    end
    
    return l_table
end

local function get_today_games(url)
    local data = process_url(url)
    if data == nil then return end
    local games_t = data.fixtures
    
    local games = ''
    local matchday = ''
    for i=1, #games_t do
        if get_curr_date() == string.sub(games_t[i].date, 1,10) then
                games = games..games_t[i].homeTeamName.." - "..games_t[i].awayTeamName
                if games_t[i].result.goalsHomeTeam ~= nil then
                    games = games.." ("..games_t[i].result.goalsHomeTeam.." - "..games_t[i].result.goalsAwayTeam..")\n"
                else
                    games = games.."\n"
                end
                games = games.."["..games_t[i].status..
                " - TIME: "..string.sub(games_t[i].date, 12,19).."]\n\n"
                matchday = games_t[i].matchday
        end
    end
    
    if games == nil or games == '' then
        games = 'No games programmed today.'
    else
            local suffix = get_suffix(matchday)
            games = games.."\n\nDAY NUMBER: "..matchday..suffix
    end
    return games
end

local function get_games(matchday, url)
    local data = process_url(url.."?matchday="..matchday)
    if data == nil then return end
    local games_t = data.fixtures
    
    local suffix = get_suffix(matchday)
    local games = 'GAMES OF '..matchday..suffix..' DAY: \n\n'
    for i=1, #games_t do
        games = games..games_t[i].homeTeamName.." - "..games_t[i].awayTeamName
        if games_t[i].result.goalsHomeTeam ~= nil then
            games = games.." ("..games_t[i].result.goalsHomeTeam.." - "..games_t[i].result.goalsAwayTeam..")\n"
        else
            games = games.."\n"
        end
        games = games.."["..games_t[i].status..
        " - DATE: "..string.sub(games_t[i].date, 1,10).." ("..string.sub(games_t[i].date, 12,19)..")]\n\n"
    end
    
    return games
end

local function run(msg, matches)
    if not matches[2] then
        return get_leagues()
    else
        local url = get_league_url(matches[2])
        if url == nil then
           return 'Code you inserted is not valid. Execute /football to know more.'
        end
        
        if not matches[3] then
           url = url.."/fixtures"
           return get_today_games(url)
        elseif string.match(matches[3],"%d+") then
           url = url.."/fixtures"
           return get_games(matches[3], url)
        elseif string.match(matches[3],"rank") then
           url = url.."/leagueTable"
           return get_league_table(url)
        else
           return 'Not valid command. Type "/help football" for more infos.'
        end
    end
end

return {
  description = "Updates on football of over Europe.",
  usage = {
        "/football : Returns Leagues codes.",
        "/football [league_code] : Returns today's matches.",
        "/football [league_code] [matchday_number] : Returns all matchday's number matches.",
        "/football [league_code] rank : Returns the updated leaguetable of the league."
  },
  patterns = {
        "^(/football)$",
        "^(/football) ([%a][%w]+)$",
        "^(/football) ([%a][%w]+) ([%d]+)$",
        "^(/football) ([%a][%w]+) (rank)$"
  },
  run = run
}