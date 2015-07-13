local class = require 'libs/middleclass'

local Maps = class('Maps')

function Maps:initialize()
	self.maps = {}
	self.map_names = {}
    local s = "\n"
    for token in love.filesystem.read( "levels_new.lua"):gmatch("(.-)"..s.."()") do
        table.insert(self.maps, self:read(token))
    end
    for token in love.filesystem.read( "levels_names.lua"):gmatch("(.-)"..s.."()") do
        table.insert(self.map_names, token)
    end
end

function Maps:read(map)
    local data = {}
    for token in map:gmatch("%w+") do
       table.insert(data, tonumber(token))
    end
    return data
end

function Maps:get_maps()
	return self.maps
end

return Maps
