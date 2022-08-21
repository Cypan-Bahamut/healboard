--[[
    The entire mergedplayer file exists to flatten individual stats in the db
    into two numbers (per name). So normally the db is:
    hps_db.dp[mob_name][player_name] = {stats}
    Mergedplayer iterates over mob_name and returns a table that's just:
    tab[player_name] = {CalculatedStatA,CalculatedStatB}
]]

local MergedPlayer = {}

function MergedPlayer:new (o)
    o = o or {}

    assert(o.players and #o.players > 0,
           "MergedPlayer constructor requires at least one Player instance.")

    setmetatable(o, self)
    self.__index = self

    return o
end

--[[
    'healavg', 'healrange'
]]


function MergedPlayer:healavg()
    local heals, heal_amt = 0, 0

    for _, p in ipairs(self.players) do
        heals    = heals + p.heals
        heal_amt = heal_amt + p.heals*p.avg_heal
    end

    if heals > 0 then
        return { heal_amt / heals, heals}
    else
        return {0, 0}
    end
end


function MergedPlayer:healrange()
    local min_heal, max_heal = math.huge, 0

    for _, p in ipairs(self.players) do
        min_heal = math.min(min_heal, p.min_heal)
        max_heal = math.max(max_heal, p.max_heal)
    end

    return {min_heal~=math.huge and min_heal or max_heal, max_heal}
end


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
