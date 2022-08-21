-- healboard addon for Windower4. See readme.md for a complete description.

_addon.name = 'healboard'
_addon.author = 'Suji'
_addon.version = '1.14'
_addon.commands = {'hd', 'healboard'}

require('tables')
require('strings')
require('maths')
require('logger')
require('actions')
local file = require('files')
config = require('config')

local Display = require('display')
local display
hps_clock = require('hpsclock'):new() -- global for now
hps_db    = require('healingdb'):new() -- global for now

-------------------------------------------------------

-- Conventional settings layout
local default_settings = {}
default_settings.numplayers = 8
default_settings.hbcolor = 204
default_settings.showallihps = true
default_settings.resetfilters = true
default_settings.visible = true
default_settings.showfellow = true
default_settings.UpdateFrequency = 0.5
default_settings.combinepets = true

default_settings.display = {}
default_settings.display.pos = {}
default_settings.display.pos.x = 500
default_settings.display.pos.y = 100

default_settings.display.bg = {}
default_settings.display.bg.alpha = 200
default_settings.display.bg.red = 0
default_settings.display.bg.green = 0
default_settings.display.bg.blue = 0

default_settings.display.text = {}
default_settings.display.text.size = 10
default_settings.display.text.font = 'Courier New'
default_settings.display.text.fonts = {}
default_settings.display.text.alpha = 255
default_settings.display.text.red = 255
default_settings.display.text.green = 255
default_settings.display.text.blue = 255

settings = config.load(default_settings)

-- Accepts msg as a string or a table
function hb_output(msg)
    local prefix = 'hb: '
    local color  = settings['hbcolor']

    if type(msg) == 'table' then
        for _, line in ipairs(msg) do
            windower.add_to_chat(color, prefix .. line)
        end
    else
        windower.add_to_chat(color, prefix .. msg)
    end
end

-- Handle addon args
windower.register_event('addon command', function()
    local chatmodes = S{'s', 'l', 'l2', 'p', 't', 'say', 'linkshell', 'linkshell2', 'party', 'tell', 'echo'}

    return function(command, ...)
        if command == 'e' then
            assert(loadstring(table.concat({...}, ' ')))()
            return
        end

        command = (command or 'help'):lower()
        local params = {...}

        if command == 'help' then
            hb_output('healboard v' .. _addon.version .. '. Author: Suji')
            hb_output('hb help : Shows help message')
            hb_output('hb pos <x> <y> : Positions the healboard')
            hb_output('hb reset : Reset healing')
            hb_output('hb report [<target>] : Reports healing. Can take standard chatmode target options.')
            hb_output('hb reportstat <stat> [<player>] [<target>] : Reports the given stat. Can take standard chatmode target options. Ex: //hb rs acc p')
            hb_output('Valid chatmode targets are: ' .. chatmodes:concat(', '))
            hb_output('hb filter show  : Shows current filter settings')
            hb_output('hb filter add <mob1> <mob2> ... : Add mob patterns to the filter (substrings ok)')
            hb_output('hb filter clear : Clears mob filter')
            hb_output('hb visible : Toggles healboard visibility')
            hb_output('hb stat <stat> [<player>]: Shows specific healing stats. Respects filters. If player isn\'t specified, ' ..
                  'stats for everyone are displayed. Valid stats are:')
            hb_output(hps_db.player_stat_fields:tostring():stripchars('{}"'))
        elseif command == 'pos' then
            if params[2] then
                local posx, posy = tonumber(params[1]), tonumber(params[2])
                settings.display.pos.x = posx
                settings.display.pos.y = posy
                config.save(settings)
                display:set_position(posx, posy)
            end
        elseif command == 'set' then
            if not params[2] then
                return
            end

            local setting = params[1]
            if setting == 'combinepets' then
                if params[2] == 'true' then
                    settings.combinepets = true
                elseif params[2] == 'false' then
                    settings.combinepets = false
                else
                    error("Invalid value for 'combinepets'. Must be true or false.")
                    return
                end
                settings:save()
                hb_output("Setting 'combinepets' set to " .. tostring(settings.combinepets))
            elseif setting == 'numplayers' then
                settings.numplayers = tonumber(params[2])
                settings:save()
                display:update()
                hb_output("Setting 'numplayers' set to " .. settings.numplayers)
            elseif setting == 'bgtransparency' then
                settings.display.bg.alpha  = tonumber(params[2])
                settings:save()
                display:update()
                hb_output("Setting 'bgtransparency' set to " .. settings.display.bg.alpha)
            elseif setting == 'font' then
                settings.display.text.font = params[2]
                settings:save()
                display:update()
                hb_output("Setting 'font' set to " .. settings.display.text.font)
            elseif setting == 'hbcolor' then
                settings.hbcolor = tonumber(params[2])
                settings:save()
                hb_output("Setting 'hbcolor' set to " .. settings.hbcolor)
            elseif setting == 'showallihps' then
                if params[2] == 'true' then
                    settings.showallihps = true
                elseif params[2] == 'false' then
                    settings.showallihps = false
                else
                    error("Invalid value for 'showallihps'. Must be true or false.")
                    return
                end

                settings:save()
                hb_output("Setting 'showallhps' set to " .. tostring(settings.showallihps))
            elseif setting == 'resetfilters' then
                if params[2] == 'true' then
                    settings.resetfilters = true
                elseif params[2] == 'false' then
                    settings.resetfilters = false
                else
                    error("Invalid value for 'resetfilters'. Must be true or false.")
                    return
                end

                settings:save()
                hb_output("Setting 'resetfilters' set to " .. tostring(settings.resetfilters))
            elseif setting == 'showfellow' then
                if params[2] == 'true' then
                    settings.showfellow = true
                elseif params[2] == 'false' then
                    settings.showfellow = false
                else
                    error("Invalid value for 'showfellow'. Must be true or false.")
                    return
                end

                settings:save()
                hb_output("Setting 'showfellow' set to " .. tostring(settings.showfellow))
            end
        elseif command == 'reset' then
            reset()
        elseif command == 'report' then
            local arg = params[1]
            local arg2 = params[2]

            if arg then
                if chatmodes:contains(arg) then
                    if arg == 't' or arg == 'tell' then
                        if not arg2 then
                            -- should be a valid player name
                            error('Invalid argument for report t: Please include player target name.')
                            return
                        elseif not arg2:match('^[a-zA-Z]+$') then
                            error('Invalid argument for report t: ' .. arg2)
                        end
                    end
                else
                    error('Invalid parameter passed to report: ' .. arg)
                    return
                end
            end

            display:report_summary(arg, arg2)

        elseif command == 'visible' then
            display:update()
            display:visibility(not settings.visible)

        elseif command == 'filter' then
            local subcmd
            if params[1] then
                subcmd = params[1]:lower()
            else
                error('Invalid option to //hb filter. See //hb help')
                return
            end

            if subcmd == 'add' then
                for i=2, #params do
                    hps_db:add_filter(params[i])
                end
                display:update()
            elseif subcmd == 'clear' then
                hps_db:clear_filters()
                display:update()
            elseif subcmd == 'show' then
                display:report_filters()
            else
                error('Invalid argument to //hb filter')
            end
        elseif command == 'stat' then
            if not params[1] or not hps_db.player_stat_fields:contains(params[1]:lower()) then
                error('Must pass a stat specifier to //hb stat. Valid arguments: ' ..
                      hps_db.player_stat_fields:tostring():stripchars('{}"'))
            else
                local stat = params[1]:lower()
                local player = params[2]
                display:show_stat(stat, player)
            end
        elseif command == 'reportstat' or command == 'rs' then
            if not params[1] or not hps_db.player_stat_fields:contains(params[1]:lower()) then
                error('Must pass a stat specifier to //hb reportstat. Valid arguments: ' ..
                      hps_db.player_stat_fields:tostring():stripchars('{}"'))
                return
            end

            local stat = params[1]:lower()
            local arg2 = params[2] -- either a player name or a chatmode
            local arg3 = params[3] -- can only be a chatmode

            -- The below logic is obviously bugged if there happens to be a player named "say",
            -- "party", "linkshell" etc but I don't care enough to account for those people!

            if chatmodes:contains(arg2) then
                -- Arg2 is a chatmode so we assume this is a 3-arg version (no player specified)
                display:report_stat(stat, {chatmode = arg2, telltarget = arg3})
            else
                -- Arg2 is not a chatmode, so we assume it's a player name and then see
                -- if arg3 looks like an optional chatmode.
                if arg2 and not arg2:match('^[a-zA-Z]+$') then
                    -- should be a valid player name
                    error('Invalid argument for reportstat t ' .. arg2)
                    return
                end

                if arg3 and not chatmodes:contains(arg3) then
                    error('Invalid argument for reportstat t ' .. arg2 .. ', must be a valid chatmode.')
                    return
                end

                display:report_stat(stat, {player = arg2, chatmode = arg3, telltarget = params[4]})
            end
        elseif command == 'fields' then
            error("Not implemented yet.")
            return
        elseif command == 'save' then
            if params[1] then
                if not params[1]:match('^[a-ZA-Z0-9_-,.:]+$') then
                    error("Invalid filename: " .. params[1])
                    return
                end
                save(params[1])
            else
                save()
            end
        else
            error('Unrecognized command. See //hb help')
        end
    end
end())

local months = {
    'jan', 'feb', 'mar', 'apr',
    'may', 'jun', 'jul', 'aug',
    'sep', 'oct', 'nov', 'dec'
}


function save(filename)
    if not filename then
        local date = os.date("*t", os.time())
        filename = string.format("hb_%s-%d-%d-%d-%d.txt",
                                  months[date.month],
                                  date.day,
                                  date.year,
                                  date.hour,
                                  date.min)
    end
    local parse = file.new('data/parses/' .. filename)

    if parse:exists() then
        local dup_path = file.new(parse.path)
        local dup = 0

        while dup_path:exists() do
            dup_path = file.new(parse.path .. '.' .. dup)
            dup = dup + 1
        end
        parse = dup_path
    end

    parse:create()
end


-- Resets application state
function reset()
    if settings.resetfilters then
        hps_db:clear_filters()
    end
    display:reset()
    hps_clock:reset()
    hps_db:reset()
end


display = Display:new(settings, hps_db)


-- Keep updates flowing
local function update_hps_clock()
    local player = windower.ffxi.get_player()
    local pet
    if player ~= nil then
        local player_mob = windower.ffxi.get_mob_by_id(player.id)
        if player_mob ~= nil then
            local pet_index = player_mob.pet_index
            if pet_index ~= nil then
                pet = windower.ffxi.get_mob_by_index(pet_index)
            end
        end
    end
    if player and (player.in_combat or (pet ~= nil and pet.status == 1)) then
        hps_clock:advance()
    else
        hps_clock:pause()
    end

    display:update()
end


-- Returns all mob IDs for anyone in your alliance, including their pets.
function get_ally_mob_ids()
    local allies = T{}
    local party = windower.ffxi.get_party()

    for _, member in pairs(party) do
        if type(member) == 'table' and member.mob then
            allies:append(member.mob.id)
            if member.mob.pet_index and member.mob.pet_index> 0 and windower.ffxi.get_mob_by_index(member.mob.pet_index) then
                allies:append(windower.ffxi.get_mob_by_index(member.mob.pet_index).id)
            end
        end
    end

    if settings.showfellow then
        local fellow = windower.ffxi.get_mob_by_target("ft")
        if fellow ~= nil then
            allies:append(fellow.id)
        end
    end

    return allies
end


-- Returns true if is someone (or a pet of someone) in your alliance.
function mob_is_ally(mob_id)
    -- get zone-local ids of all allies and their pets
    return get_ally_mob_ids():contains(mob_id)
end


function action_handler(raw_actionpacket)
    local actionpacket = ActionPacket.new(raw_actionpacket)

    local category = actionpacket:get_category_string()

    local player = windower.ffxi.get_player()
    local pet
    if player ~= nil then
        local player_mob = windower.ffxi.get_mob_by_id(player.id)
        if player_mob ~= nil then
            local pet_index = player_mob.pet_index
            if pet_index ~= nil then
                pet = windower.ffxi.get_mob_by_index(pet_index)
            end
        end
    end
    if not player or not (windower.ffxi.get_player().in_combat or (pet ~= nil and pet.status == 1)) then
        -- nothing to do
        return
    end

    for target in actionpacket:get_targets() do
        for subactionpacket in target:get_actions() do
            if (mob_is_ally(actionpacket.raw.actor_id) and mob_is_ally(target.raw.id)) then
                local main  = subactionpacket:get_basic_info()
                local add   = subactionpacket:get_add_effect()
                local spike = subactionpacket:get_spike_effect()
                if main.message_id == 7 or main.message_id == 102 or main.message_id == 122 or
                main.message_id == 321 or main.message_id == 306 or main.message_id == 367 or
                main.message_id == 387 or main.message_id == 606 or main.message_id == 306 or
                main.message_id == 24 or main.message_id == 122 or main.message_id == 26 or
                main.message_id == 167 or main.message_id == 263 or main.message_id == 318 then
                    hps_db:add_heal(target:get_name(), create_mob_name(actionpacket), main.param)
                end
            end
        end
    end
end

ActionPacket.open_listener(action_handler)

    function find_pet_owner_name(actionpacket)
        local pet = windower.ffxi.get_mob_by_id(actionpacket:get_id())
        local party = windower.ffxi.get_party()

        local name = nil

        for _, member in pairs(party) do
            if type(member) == 'table' and member.mob then
                if member.mob.pet_index and member.mob.pet_index> 0 and pet.index == member.mob.pet_index then
                    name = member.mob.name
                    break
                end
            end
        end
        return name, pet.name
    end

    function create_mob_name(actionpacket)
        local actor = actionpacket:get_actor_name()
        local result = ''
        local owner, pet = find_pet_owner_name(actionpacket)
        if owner ~= nil then
            if string.len(actor) > 8 then
                result = string.sub(actor, 1, 7)..'.'
            else
                result = actor
            end
            if settings.combinepets then
                result = ''
            else
                result = actor
            end
            if pet then
                result = '('..owner..')'..' '..pet
            end
        else
            return actor
        end
        return result
    end

config.register(settings, function(settings)
    update_hps_clock:loop(settings.UpdateFrequency)
    display:visibility(display.visible and windower.ffxi.get_info().logged_in)
end)


--[[
Copyright � 2013-2014, Jerry Hebert
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
