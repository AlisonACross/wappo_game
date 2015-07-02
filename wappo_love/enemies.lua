local class = require 'libs/middleclass'
local Unit = require 'unit'

local Enemies = class('Enemies')

function Enemies:initialize()
	self.list = {}
	self.moving_enemies_count = 0
	self.moved = false
	self.killed = false
end

function Enemies:update(dt)
	-- """
	-- Update Enemies animations
	-- """
    for i=1,#self.list do
        self.list[i]:update(dt)
    end
end

function Enemies:draw()
	-- """
	-- Draw Enemies sprites
	-- """
    for i=1,#self.list do
        self.list[i]:draw()
    end
end

function Enemies:add_enemy(enemy_type, x, y)
	-- """
	-- Add enemy to Enemies object
	-- """
	table.insert(self.list, Unit:new(enemy_type, x, y))
end

function Enemies:delete_enemy(position)
	-- """
	-- Delete enemy from Enemies object
	-- """
	table.remove(self.list, position)
end

function Enemies:check_transformation()
	-- """
	-- Check if there exist red and blue enemies on the same position
	-- Change them to violet enemy
	-- """
    for i=1, #self.list do
        for j=1, #self.list do
            if self.list[i] ~= self.list[j] and self.list[i].x == self.list[j].x and 
            		self.list[i].y == self.list[j].y and self.list[i].index ~= 3 and
            		self.list[j].index ~= 3 then
                self:add_enemy('violet enemy', self.list[i].x, self.list[i].y)
                self:delete_enemy(j)
                self:delete_enemy(i)
                return
            end
        end
    end
end

function Enemies:set_steps()
	-- """
	-- Set number of steps for each enemy depending on his type
	-- """
    for i=1,#self.list do
        if self.list[i].index== 2 or self.list[i].index== 4 then
            self.list[i].steps_left = self.list[i].steps
        elseif self.list[i].index == 3 then
            self.list[i].steps_left = self.list[i].steps
        end
    end
end

function Enemies:move()
    self:set_steps()
    self.moving_enemy_count = 1
    self:steps_processing()
end

function Enemies:is_here(x, y)
    -- """
    -- Check if enemy in this cell
    -- """
    for i=1,#self.list do
        return self.list[i]:is_here(x, y)
    end
    return false
end

function Enemies:kills()
    -- """
    -- Enemies kills player
    -- """
    print('you was killed')
    for i=1,#self.list do
    	self.list[i].steps_left = 0
        self.list[i].animation = self.list[i].animations.kill
    end
	self.moved = true
	level.player.moved = true
	level.moved = false
end

function Enemies:is_moved()
	return self.moved
end

function Enemies:is_kill(unit)
	if level.player:is_here(unit.x, unit.y) == true then
		return true
	end
	return false
end

function Enemies:check_steps()
	for i=1,#self.list do
		if self.list[i].steps_left ~= 0 then
			return
		end
	end
	if self.moving_enemy_count ~= 0 then
		return
	end
	self.moved = true
	level:move()
end

function Enemies:steps_processing()
    self.moving_enemy_count = self.moving_enemy_count - 1
    if self.moving_enemy_count == 0 then
        self:check_transformation()
        self:step_processing()
    end
end


function Enemies:step_processing()
    for i=1,#self.list do
        if self.list[i].steps_left>0 then
	        self.list[i].steps_left = self.list[i].steps_left - 1
	        local directions = level.player:get_directions(self.list[i].x, self.list[i].y)
	        local ways = {}
	        for k, v in pairs(self.list[i].ways) do 
	            if directions[v][1]~=0 or directions[v][2]~=0 then 
	                ways[#ways+1] = directions[v] 
	            end
	        end
	        for k, way in pairs(ways) do
	            if way[1]~=0 and way[2]~=0 then
	                if level.floor:is_permeable(self.list[i], 0, way[2]) and
		                	level.floor:is_permeable(self.list[i], way[1], 0) and
		                	level.floor:is_permeable(self.list[i], way[1]*2, way[2]) and
		                	level.floor:is_permeable(self.list[i], way[1], way[2]*2) then
	                    level.floor:crash(self.list[i].x, self.list[i].y+way[2])
	                	level.floor:crash(self.list[i].x+way[1], self.list[i].y)
	                	level.floor:crash(self.list[i].x+way[1]*2, self.list[i].y+way[2])
	                	level.floor:crash(self.list[i].x+way[1], self.list[i].y+way[2]*2)
	                    self.moving_enemy_count = self.moving_enemy_count + 1
	                    self.list[i]:move(way)
	                    if self:is_kill(self.list[i]) then
	                    	self.killed = true
	                    end
	                    flux.to(self.list[i], level.tweeking_time, { anim_x = 0, anim_y = 0 }):ease(level.tweeking_ease):oncomplete(function () self:steps_processing() end)
	                    break
	                end
	            else
	            	if level.floor:is_permeable(self.list[i], way[1], way[2]) == false then
						if k == #ways then
							self.list[i].steps_left = 0
                        end
	            	else
	                    if level.movable:is_here(self.list[i].x+way[1]*2, self.list[i].y+way[2]*2) == true then
	                        if k == #ways then
	                        	self.list[i].steps_left = 0
	                        end
	                    else
	                    	if self:is_here(self.list[i].x+way[1]*2, self.list[i].y+way[2]*2) == true then
	                            self.moving_enemy_count = self.moving_enemy_count + 1
	                            if self.list[i].description=='violet enemy' then
			                    	level.floor:crash(self.list[i].x+way[1], self.list[i].y+way[2])
			                    end
	                            self.list[i]:move(way)
	                            print(self:is_kill(self.list[i]))
	                            flux.to(self.list[i], level.tweeking_time, { anim_x = 0, anim_y = 0 }):ease(level.tweeking_ease):oncomplete(function () self:steps_processing() end)
	                            break
	                        else
	                            -- print("not unit")
	                            -- если клетка пустая то unit туда идет
	                            self.moving_enemy_count = self.moving_enemy_count + 1
	                            if self.list[i].description=='violet enemy' then
			                    	level.floor:crash(self.list[i].x+way[1], self.list[i].y+way[2])
			                    end
	                            self.list[i]:move(way)
        	                    if self:is_kill(self.list[i]) then
			                    	self.killed = true
			                    end
	                            -- смотрим какие floor есть на этой клетке
	                            -- если никаких или выход то ставим обычный твининг
	                            if level.floor:get_index(self.list[i].x, self.list[i].y) == 7 then
	                            	self.list[i].steps_left = 0
	                            	if self:is_kill(self.list[i]) == false then
		                                flux.to(self.list[i], level.tweeking_time, { anim_x = 0, anim_y = 0 }):ease(level.tweeking_ease):oncomplete(function () level.floor:teleportation(self.list[i])
		                                                                                                                                self:steps_processing() end)
		                            else
		                            	self.killed = true
		                            	break
		                            end
	                                break
	                            else
	                            	flux.to(self.list[i], level.tweeking_time, { anim_x = 0, anim_y = 0 }):ease(level.tweeking_ease):oncomplete(function () self:steps_processing() end)
	                            	break
	                            end
	                        end
	                    end
	                end
	            end
	        end
            if self.killed == true then
				self:kills()
			end
        end
    end
    self:check_steps()
end

return Enemies