local Player = require 'player'
local MergedPlayer = require 'mergedplayer'

local healingDB = {
    db = T{},
    filter = T{}
}

--[[
healingDB.player_stat_fields = T{
    'min_heal', 'max_heal', 'avg_heal'
}
]]

healingDB.player_stat_fields = T{
    'healavg', 'healrange'
}

function healingDB:new (o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    return o
end


function healingDB:iter()
    local k, v
    return function ()
        k, v = next(self.db, k)
        while k and not self:_filter_contains_mob(k) do
            k, v = next(self.db, k)
        end

        if k then
            return k, v
        end
    end
end


function healingDB:get_filters()
    return self.filter
end


function healingDB:_filter_contains_mob(mob_name)
    if self.filter:empty() then
        return true
    end

    for _, mob_pattern in ipairs(self.filter) do
        if mob_name:lower():find(mob_pattern:lower()) then
            return true
        end
    end
    return false
end


function healingDB:clear_filters()
    self.filter = T{}
end


function healingDB:add_filter(mob_pattern)
    if mob_pattern then self.filter:append(mob_pattern) end
end


-- Returns the corresponding Player instance. Will create it if necessary.
function healingDB:_get_player(mob, player_name)
    if not self.db[mob] then
        self.db[mob] = T{}
    end

    if not self.db[mob][player_name] then
        self.db[mob][player_name] = Player:new{name = player_name}
    end

    return self.db[mob][player_name]
end


-- Returns a table {player1 = stat1, player2 = stat2...}.
-- For WS queries, the stat value is a sub-table of {ws1 = ws_stat1, ws2 = ws_stat2}.
function healingDB:query_stat(stat, player_name)
    local players = T{}

    if player_name and player_name:match('^[a-zA-Z]+$') then
        player_name = player_name:lower():ucfirst()
    end

    -- Gather a table mapping player names to all of the corresponding Player instances
    for mob, mob_players in self:iter() do
        for name, player in pairs(mob_players) do
            if player_name and player_name == name or
               not player_name and not player.is_sc then
                if players[name] then
                    players[name]:append(player)
                else
                    players[name] = T{player}
                end
            end
        end
    end

    -- Flatten player subtables into the merged stat we desire
    for name, instances in pairs(players) do
        local merged = MergedPlayer:new{players = instances}
        players[name] = MergedPlayer[stat](merged)
    end

    return players
end


function healingDB:empty()
    return self.db:empty()
end


function healingDB:reset()
    self.db = T{}
end


--[[
The following player dispatchers all fetch the correct
instance of Player for a given mob and then dispatch the
method for data accmulation.
]]--

function healingDB:add_heal(m, p, d)      self:_get_player(m, p):add_heal(d)       end
function healingDB:add_healing(m, p, d)   self:_get_player(m, p):add_healing(d)    end

return healingDB

--[[
Copyright (c) 2013, Jerry Hebert
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of healboard nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL JERRY HEBERT BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL healingS
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH healing.
]]
