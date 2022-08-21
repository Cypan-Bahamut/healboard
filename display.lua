-- Display object
local texts = require('texts')

local Display = {
    visible = true,
    settings = nil,
    tb_name = 'healboard'
}

local valid_fonts = T{
    'fixedsys',
    'lucida console',
    'courier',
    'courier new',
    'ms mincho',
    'consolas',
    'dejavu sans mono'
}

local valid_fields = T{
    'name',
    'hps',
    'percent',
    'total',
    'healavg',
    'healrange'
}


function Display:set_position(posx, posy)
    self.text:pos(posx, posy)
end

function Display:new(settings, db)
    local repr = setmetatable({db = db}, self)
    self.settings = settings
    self.__index = self
    self.visible = settings.visible

    self.text = texts.new(settings.display, settings)

    if not valid_fonts:contains(self.settings.display.text.font:lower()) then
        error('Invalid font specified: ' .. self.settings.display.text.font)
        self.text:font(self.settings.display.text.font)
        self.text:size(self.settings.display.text.fontsize)
    else
        self.text:font(self.settings.display.text.font, 'consolas', 'courier new', 'monospace')
        self.text:size(self.settings.display.text.size)
    end

    self:visibility(self.visible)

    return repr
end


function Display:visibility(v)
    if v then
        self.text:show()
    else
        self.text:hide()
    end

    self.visible = v
    self.settings.visible = v
    self.settings:save()
end


function Display:report_filters()
    local mob_str
    local filters = self.db:get_filters()

    if filters:empty() then
        mob_str = "healboard filters: None (Displaying healing for all mobs)"
    else
        mob_str = "healboard filters: " .. filters:concat(', ')
    end
    windower.add_to_chat(55, mob_str)

end


-- Returns the string for the healboard header with updated info
-- about current mob filtering and whether or not time is currently
-- contributing to the hps value.
function Display:build_healboard_header()
    local mob_filter_str
    local filters = self.db:get_filters()

    if filters:empty() then
        mob_filter_str = 'All'
    else
        mob_filter_str = table.concat(filters, ', ')
    end

    local labels
    if self.db:empty() then
        labels = '\n'
    else
        labels = '%32s%7s%9s\n':format('Tot', 'Pct', 'hps')
    end

    local hps_status
    if hps_clock:is_active() then
        hps_status = 'Active'
    else
        hps_status = 'Paused'
    end

    local hps_clock_str = ''
    if hps_clock:is_active() or hps_clock.clock > 1 then
        hps_clock_str = ' (%s)':format(hps_clock:to_string())
    end

    local hps_chunk = 'hps: %s%s':format(hps_status, hps_clock_str)

    return '%s%s\nMobs: %-9s\n%s':format(hps_chunk, ' ':rep(29 - hps_chunk:len()) .. '//sb help', mob_filter_str, labels)
end


-- Returns following two element pair:
-- 1) table of sorted 2-tuples containing {player, healing}
-- 2) integer containing the total healing done
function Display:get_sorted_player_healing()
    -- In order to sort by healing, we have to first add it all up into a table
    -- and then build a table of sortable 2-tuples and then finally we can sort...
    local mob, players
    local player_total_dmg = T{}

    if self.db:empty() then
        return {}, 0
    end

    for mob, players in self.db:iter() do
        -- If the filter isn't active, include all mobs
        for player_name, player in pairs(players) do
            if player_total_dmg[player_name] then
                player_total_dmg[player_name] = player_total_dmg[player_name] + player.healing
            else
                player_total_dmg[player_name] = player.healing
            end
        end
    end

    local sortable = T{}
    local total_healing = 0
    for player, healing in pairs(player_total_dmg) do
        total_healing = total_healing + healing
        sortable:append({player, healing})
    end

    table.sort(sortable, function(a, b)
        return a[2] > b[2]
    end)

    return sortable, total_healing
end


-- Updates the main display with current filter/healing/hps status
function Display:update()
    if not self.visible then
        -- no need build a display while it's hidden
        return
    end

    if self.db:empty() then
        self:reset()
        return
    end
    local healing_table, total_healing
    healing_table, total_healing = self:get_sorted_player_healing()

    local display_table = T{}
    local player_lines = 0
    local alli_healing = 0
    for k, v in pairs(healing_table) do
        if player_lines < self.settings.numplayers then
            local hps
            if hps_clock.clock == 0 then
                hps = "N/A"
            else
                hps = '%.2f':format(math.round(v[2] / hps_clock.clock, 2))
            end

            local percent
            if total_healing > 0 then
                percent = '(%.1f%%)':format(100 * v[2] / total_healing)
            else
                percent = '(0%)'
            end
            display_table:append('%-25s%7d%8s %7s':format(v[1], v[2], percent, hps))
        end
        alli_healing = alli_healing + v[2] -- gather this even for players not displayed
        player_lines = player_lines + 1
    end

    if self.settings.showallihps and hps_clock.clock > 0 then
        display_table:append('-':rep(17))
        display_table:append('Alli hps: ' .. '%7.1f':format(alli_healing / hps_clock.clock))
    end

    self.text:text(self:build_healboard_header() .. table.concat(display_table, '\n'))
end


local function build_input_command(chatmode, tell_target)
    local input_cmd = 'input '
    if chatmode then
        input_cmd = input_cmd .. '/' .. chatmode .. ' '
        if tell_target then
            input_cmd = input_cmd .. tell_target .. ' '
        end
    end

    return input_cmd
end

-- Takes a table of elements to be wrapped across multiple lines and returns
-- a table of strings, each of which fits within one FFXI line.
local function wrap_elements(elements, header, sep)
    local max_line_length = 120 -- game constant
    if not sep then
        sep = ', '
    end

    local lines = T{}
    local current_line = nil
    local line_length

    local i = 1
    while i <= #elements do
        if not current_line then
            current_line = T{}
            line_length = header:len()
            lines:append(current_line)
        end

        local new_line_length = line_length + elements[i]:len() + sep:len()
        if new_line_length > max_line_length then
            current_line = T{}
            lines:append(current_line)
            new_line_length = elements[i]:len() + sep:len()
        end

        current_line:append(elements[i])
        line_length = new_line_length
        i = i + 1
    end

    local baked_lines = lines:map(function (ls) return ls:concat(sep) end)
    if header:len() > 0 and #baked_lines > 0 then
        baked_lines[1] = header .. baked_lines[1]
    end

    return baked_lines
end


local function slow_output(chatprefix, lines, limit)
    -- this is funky but if we don't wait like this, the lines will spew too fast and error
    windower.send_command(lines:map(function (l) return chatprefix .. l end):concat('; wait 1.2 ; '))
end


function Display:report_summary (...)
    local chatmode, tell_target = table.unpack({...})

    local healing_table, total_healing
    healing_table, total_healing = self:get_sorted_player_healing()

    local elements = T{}
    for k, v in pairs(healing_table) do
        elements:append('%s %d(%.1f%%)':format(v[1], v[2], 100 * v[2]/total_healing))
    end

    -- Send the report to the specified chatmode
    slow_output(build_input_command(chatmode, tell_target),
                wrap_elements(elements:slice(1, self.settings.numplayers), 'Healing: '), self.settings.numplayers)
end

-- This is a table of the line aggregators and related utilities
Display.stat_summaries = {}


Display.stat_summaries._format_title = function (msg)
        local line_length = 40
        local msg_length  = msg:len()
        local border_len = math.floor(line_length / 2 - msg_length / 2)

        return ' ':rep(border_len) .. msg .. ' ':rep(border_len)
    end


Display.stat_summaries['range'] = function (stats, filters, options)

        local lines = T{}
        for name, pair in pairs(stats) do
            lines:append('%-20s %d min   %d max':format(name, pair[1], pair[2]))
        end

        if #lines > 0 and options and options.name then
            sb_output(Display.stat_summaries._format_title('-= '..options.name..' (' .. filters .. ') =-'))
            sb_output(lines)
        end
    end


Display.stat_summaries['average'] = function (stats, filters, options)

        local lines = T{}
        for name, pair in pairs(stats) do
            if options and options.percent then
                lines:append('%-20s %.2f%% (%d sample%s)':format(name, 100 * pair[1], pair[2],
                                                                      pair[2] == 1 and '' or 's'))
            else
                lines:append('%-20s %d (%ds)':format(name, pair[1], pair[2]))
            end
        end

        if #lines > 0 and options and options.name then
            sb_output(Display.stat_summaries._format_title('-= '..options.name..' (' .. filters .. ') =-'))
            sb_output(lines)
        end
    end


-- This is a closure around a hash-based dispatcher. Some conveniences are
-- defined for the actual stat display functions.
Display.show_stat = function()
    return function (self, stat, player_filter)
        local stats = self.db:query_stat(stat, player_filter)
        local filters = self.db:get_filters()
        local filter_str

        if filters:empty() then
            filter_str = 'All mobs'
        else
            filter_str = filters:concat(', ')
        end

        Display.stat_summaries[Display.stat_summaries._all_stats[stat].category](stats, filter_str, Display.stat_summaries._all_stats[stat])
    end
end()


-- TODO: This needs to be factored somehow to take better advantage of similar
--       code already written for reporting and stat queries.
Display.stat_summaries._all_stats = T{
    ['healrange']     = {percent=false, category="range",   name='Melee Non-Crit. Range'},
    ['healavg']       = {percent=false, category="average", name='Melee Crit. Avg. healing'},}
function Display:report_stat(stat, args)
    if Display.stat_summaries._all_stats:containskey(stat) then
        local stats = self.db:query_stat(stat, args.player)

        local elements = T{}
        local header   = Display.stat_summaries._all_stats[stat].name .. ': '
        for name, stat_pair in pairs(stats) do
            if stat_pair[2] > 0 then
                if Display.stat_summaries._all_stats[stat].category == 'range' then
                    elements:append({stat_pair[1], ('%s %d~%d'):format(name, stat_pair[1], stat_pair[2])})
                elseif Display.stat_summaries._all_stats[stat].percent then
                    elements:append({stat_pair[1], ('%s %.2f%% (%ds)'):format(name, stat_pair[1] * 100, stat_pair[2])})
                else
                    elements:append({stat_pair[1], ('%s %d (%ds)'):format(name, stat_pair[1], stat_pair[2])})
                end
            end
        end
        table.sort(elements, function(a, b)
            return a[1] > b[1]
        end)

        -- Send the report to the specified chatmode
        local wrapped = wrap_elements(elements:slice(1, self.settings.numplayers):map(function (p) return p[2] end), header)
        slow_output(build_input_command(args.chatmode, args.telltarget), wrapped, self.settings.numplayers)
    end
end


function Display:reset()
    -- the number of spaces here was counted to keep the table width
    -- consistent even when there's no data being displayed
    self.text:text(self:build_healboard_header() ..
                      'Waiting for results...' ..
                      ' ':rep(17))
end


return Display

--[[
Copyright © 2013-2014, Jerry Hebert
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
