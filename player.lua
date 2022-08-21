--[[
Object to encapsulate Player battle data

For each mob fought, a separate player instance will be stored. Therefore
there will be multiple Player instances for each actual player in the game.
This allows for easier mob filtering.
]]

local Player = {}

function Player:new (o)
    o = o or {}

    assert(o.name, "Must pass a name to player constructor")
    -- attrs should be defined in Player above but due to interpreter bug it's here for now
    local attrs = {
        clock = nil,            -- specific hps clock for this player
        healing = 0,            -- total healing done by this player
        heals = 0,
        min_heal = 0,
        max_heal = 0,
        avg_heal = 0
    }
    attrs.name = o.name
    o = attrs
    if o.name:match('^Skillchain%(') then
        o.is_sc = true
    else
        o.is_sc = false
    end

    setmetatable(o, self)
    self.__index = self

    return o
end


function Player:add_healing(healing)
    self.healing = self.healing + healing
end


function Player:add_heal(healing)
    -- increment hits
    self.heals = self.heals + 1

    -- update min/max/avg melee values
    self.min_heal = math.min(self.min_heal, healing)
    self.max_heal = math.max(self.max_heal, healing)
    self.avg_heal = self.avg_heal * (self.heals - 1)/self.heals + healing/self.heals

    -- accumulate healing
    self.healing = self.healing + healing
end


-- Returns the name of this player
function Player:get_name() return self.name end



return Player

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
