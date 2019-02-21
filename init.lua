-- Hangglider mod for Minetest
-- Original code by Piezo_ (orderofthefourthwall@gmail.com)
-- 2018-11-14

-- Modifications by David G (kestral246@gmail.com)
-- 2018-11-22
-- Give visual indication that hangglider is equiped.
--     Display simple overlay with blurred struts when equiped.
--     Issue: don't know how to disable overlay in third person view.
-- Also Unequip hangglider when landing on water.
-- Attempt to linearize parabolic flight path.
--     Start gravity stronger, but gradually reduce it as descent velocity increases.
--     Don't use airstopper when equipped from the ground (descent velocity is low).
--     Slightly increase flight speed to 1.25.
-- Unequip/equip cycling mid-flight should not fly farther than continuous flight.
--     When equipping mid-air (descent velocity higher), use airstopper but increase descent slope afterwards.
--     Create airbreak flag so all equips mid-flight use faster descent.
--     Reset airbreak flag only when land (canExist goes false).
--     Issue: it wouldn't reset if land in water, use fly, and launch from air, before I added test for water,
--            not sure if there are other such cases.
-- Temporarily add hud debug display to show descent velocity, gravity override, and airbreak flag.
--     Still in process of tuning all the parameters.

-- 2018-11-24
-- For Minetest 5.x, glider's set_attach needs to be offset by 1 node
--     Switch to alternate commented line below with correct offset.
-- Additional tuning of parameters.
-- Commented out debug hud display code, prefixed with "--debug:".

-- Modifications by Piezo_
-- 2018-11-25
-- hud overlay and debug can be enabled/disabled
-- Added blender-rendered overlay for struts using the actual model.
-- Reduced airbreak penalty severity
-- gave glider limited durability.

-- Modifications by David G
-- 2018-11-27
-- Updated to Piezo_'s version. Many good improvements.
-- Slightly blurred Piezo_'s new excellent strut overlay.
-- Kept increased 1.75 speed, but now make it increase gradually too.

-- 2018-11-28
-- Detect minetest version to automatically use appropriate set_attach offset.

-- 2018-12-05
-- Remove blank.png.

-- 2018-12-07
-- Unequip hangglider if it is not longer the wielded_item, while in use.
-- Add AUX key as alternate equip option, to use with android clients.
-- Disabled wear of hangglider for now.

-- 2018-12-09
-- Wear is back and better than ever. Breaks on unequip rather than equip.
-- Adjust glider_uses below, default 50.

-- 2019-02-19
-- Add sound while gliding.

-- Configuration variables
local HUD_Overlay = true --show glider struts as overlay on HUD
local debug = false --show debug info in top-center of hud
local glider_uses = 50 -- define number of uses before hangglider wears out
-- End configuration

hangglider = {} --Make this global, so other mods can tell if hangglider exists.
local handles = {}
hangglider.use = {}
local prev_equip_key = {}
if HUD_Overlay then
hangglider.id = {}  -- hud id for displaying overlay with struts
end
if debug then  hangglider.debug = {} end -- hud id for debug data
hangglider.airbreak = {}  -- true if falling fast when equip

local wear_incr = math.floor(65535 / glider_uses)
local isFive = string.sub(minetest.get_version().string, 1, 1) == "5"

minetest.register_entity("hangglider:airstopper", { --A one-instant entity that catches the player and slows them down.
	hp_max = 3,
	is_visible = false,
	immortal = true,
	attach = nil,
	on_step = function(self, _)
		if self.object:get_hp() ~= 1 then
			self.object:set_hp(self.object:get_hp() - 1)
		else
			if self.attach then
				self.attach:set_detach()
			end
			self.object:remove()
		end
	end
})

minetest.register_entity("hangglider:glider", {
	visual = "mesh",
	visual_size = {x = 12, y = 12},
	mesh = "glider.obj",
	immortal = true,
	static_save = false,
	textures = {"wool_white.png","default_wood.png"},
	on_step = function(self, _)
		local canExist = false
		if self.object:get_attach() then
			local player = self.object:get_attach("parent")
			if player then
				local pname = player:get_player_name()
				local itemstack = player:get_wielded_item()
				local pos = player:get_pos()
				if hangglider.use[pname] then
					local mrn_name = minetest.registered_nodes[minetest.get_node(vector.new(pos.x, pos.y-0.5, pos.z)).name]
					if mrn_name then
						if not (mrn_name.walkable or (mrn_name.drowning and mrn_name.drowning == 1)) then
							canExist = true
							local vel = player:get_player_velocity()
							local grav = player:get_physics_override().gravity
							local newspeed = player:get_physics_override().speed
							if debug then player:hud_change(hangglider.debug[pname].id, "text", 'vy='..vel.y..', sp='..newspeed..', g='..grav..', '..tostring(hangglider.airbreak[pname])) end
							-- If airbreaking used, increase the descent progression to not give
							-- mid-flight unequip/equip cycles a distance advantage.
							if hangglider.airbreak[pname] then
								if vel.y <= -4.0 then
									grav = -0.2 --Extreme measures are needed, as sometimes speed will get a bit out of control
								elseif vel.y <= -2.0 then
									grav = -0.02
								elseif vel.y <= -1.75 then
									grav = 0.00125  -- *1
								elseif vel.y <= -1.5 then
									grav = 0.0025  -- *2
								elseif vel.y <= -1.25 then
									grav = 0.005  -- *2
								elseif vel.y <= -1 then
									grav = 0.015  -- *3
								elseif vel.y <= -0.75 then
									grav = 0.04  -- *4
								elseif vel.y <= -0.5 then
									grav = 0.08  -- *4
								elseif vel.y <= -0.25 then
									grav = 0.12  -- *3
								elseif vel.y <= 0 then
									grav = 0.3  -- *3
								else  -- vel.y > 0
									grav = 0.75  -- *1.5
								end
							else  -- normal descent progression
								if vel.y <= -4.0 then
									grav = -0.2
								elseif vel.y <= -2.0 then
									grav = -0.02
								elseif vel.y <= -1.5 then
									grav = 0.00125
								elseif vel.y <= -1.25 then
									grav = 0.0025
								elseif vel.y <= -1 then
									grav = 0.005
								elseif vel.y <= -0.75 then
									grav = 0.01
								elseif vel.y <= -0.5 then
									grav = 0.02
								elseif vel.y <= -0.25 then
									grav = 0.04
								elseif vel.y <= 0 then
									grav = 0.1
								else  -- vel.y > 0
									grav = 0.5
								end
							end
							if vel.y >= 0 then
								newspeed = 1
							elseif vel.y < -2 then
								newspeed = 1.75  -- limit to 1.75
							else
								newspeed = -vel.y * 0.375 + 1  -- gradually increase from 1 to 1.75
							end
							player:set_physics_override({gravity = grav, speed = newspeed})
							if not handles[pname] then
								local handle = minetest.sound_play("hangglider_flying", {to_player = pname, gain = 0.5, loop = true})-- {object = self.object, loop = true})
								handles[pname] = handle
							end
						end
					end
				end
				if not canExist then
					player:set_physics_override({
						gravity = 1,
						jump = 1,
						speed = 1,
					})
					hangglider.use[pname] = false
					if handles[pname] then  -- stop sound if playing
						minetest.sound_stop(handles[pname])
						handles[pname] = nil
					end
					if HUD_Overlay then
					player:hud_change(hangglider.id[pname], "text", "")
					end
					hangglider.airbreak[pname] = false
					if itemstack:get_wear() + wear_incr > 65535 then
						player:set_wielded_item(nil)
						minetest.sound_play("default_tool_breaks", {pos=pos, max_hear_distance = 8, gain = 1.0})
					end
				end
			end
		end
		if not canExist then 
			self.object:set_detach()
			self.object:remove() 
		end
	end
})

minetest.register_on_dieplayer(function(player)
	local pname = player:get_player_name()
	player:set_physics_override({
		gravity = 1,
		jump = 1,
	})
	hangglider.use[pname] = false
	prev_equip_key[pname] = false
	handles[pname] = nil
end)


minetest.register_on_joinplayer(function(player)
	local pname = player:get_player_name()
	player:set_physics_override({
		gravity = 1,
		jump = 1,
	})
	hangglider.use[pname] = false
	handles[pname] = nil
	prev_equip_key[pname] = false
	if HUD_Overlay then
	hangglider.id[pname] = player:hud_add({
		hud_elem_type = "image",
		text = "",
		position = {x=0, y=0},
		scale = {x=-100, y=-100},
		alignment = {x=1, y=1},
		offset = {x=0, y=0}
	}) end
	if debug then 
		hangglider.debug[pname] = {id = player:hud_add({hud_elem_type = "text",
			position = {x=0.5, y=0.1},
			text = "-",
			number = 0xFF0000}),  -- red text
			-- ht = {50,50,50},
		}
	end
	hangglider.airbreak[pname] = false
end)

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()
	hangglider.use[pname] = nil
	handles[pname] = nil
	prev_equip_key[pname] = nil
	if HUD_Overlay then hangglider.id[pname] = nil end
	if debug then hangglider.debug[pname] = nil end
	hangglider.airbreak[pname] = nil
end)

minetest.register_tool("hangglider:hangglider", {
	description = "Glider",
	inventory_image = "glider_item.png",
	stack_max=1,
	on_use = function(itemstack, player, pointed_thing)
		if not player then
			return
		end
		local pname = player:get_player_name()
		local pos = player:get_pos()
		if minetest.get_node(vector.add(pos, {x=0,y=-1,z=0})).name == "air" and not hangglider.use[pname] then --Equip
			minetest.sound_play("bedsheet", {pos=pos, max_hear_distance = 8, gain = 1.0})
			if HUD_Overlay then player:hud_change(hangglider.id[pname], "text", "glider_struts.png") end
			local vel = player:get_player_velocity().y
			if vel < -2 then  -- engage mid-air, falling fast, so stop but ramp velocity more quickly
				hangglider.airbreak[pname] = true
				player:set_physics_override({
					gravity = 1,
					jump = 0,
					speed = 1,
				})
				local stopper = minetest.add_entity(pos, "hangglider:airstopper")
				stopper:get_luaentity().attach = player
				player:set_attach( stopper, "", {x=0,y=0,z=0}, {x=0,y=0,z=0})
			else
				player:set_physics_override({
					gravity = 0.02,
					jump = 0,
					speed = 1,
				})
			end
			hangglider.use[pname] = true
			if isFive then  -- minetest 5.x, need positive offset
				minetest.add_entity(player:get_pos(), "hangglider:glider"):set_attach(player, "", {x=0,y=10,z=0}, {x=0,y=0,z=0})
			else  -- minetest 0.4.x, no offset needed
				minetest.add_entity(player:get_pos(), "hangglider:glider"):set_attach(player, "", {x=0,y=0,z=0}, {x=0,y=0,z=0})
			end
			itemstack:add_wear(wear_incr)
			return itemstack
		elseif minetest.get_node(pos).name == "air" and hangglider.use[pname] then --Unequip
			if HUD_Overlay then player:hud_change(hangglider.id[pname], "text", "") end
			hangglider.use[pname] = false
			if itemstack:get_wear() + wear_incr > 65535 then
				player:set_wielded_item(nil)
				minetest.sound_play("default_tool_breaks", {pos=pos, max_hear_distance = 8, gain = 1.0})
			end
		end
	end,
})

-- Also can equip hangglider by using AUX key (default 'E' key).
-- Also checks that hangglider is wielded item.  If not it's unequiped.
minetest.register_globalstep(function(dtime)
    local players  = minetest.get_connected_players()
    for i,player in ipairs(players) do
		local pname = player:get_player_name()
		local itemstack = player:get_wielded_item()
		local pos = player:get_pos()
		if string.sub(itemstack:get_name(), 0, 21)== "hangglider:hangglider" then -- wielding hangglider
			local current_equip_key = player:get_player_control().aux1
			if prev_equip_key[pname] == false and current_equip_key == true then -- equip key just pressed
				if minetest.get_node(vector.add(pos, {x=0,y=-1,z=0})).name == "air" and not hangglider.use[pname] then --Equip
					minetest.sound_play("bedsheet", {pos=pos, max_hear_distance = 8, gain = 1.0})
					if HUD_Overlay then player:hud_change(hangglider.id[pname], "text", "glider_struts.png") end
					local vel = player:get_player_velocity().y
					if vel < -2 then  -- engage mid-air, falling fast, so stop but ramp velocity more quickly
						hangglider.airbreak[pname] = true
						player:set_physics_override({
							gravity = 1,
							jump = 0,
							speed = 1,
						})
						local stopper = minetest.add_entity(pos, "hangglider:airstopper")
						stopper:get_luaentity().attach = player
						player:set_attach( stopper, "", {x=0,y=0,z=0}, {x=0,y=0,z=0})
					else
						player:set_physics_override({
							gravity = 0.02,
							jump = 0,
							speed = 1,
						})
					end
					hangglider.use[pname] = true
					if isFive then  -- minetest 5.x, need positive offset
						minetest.add_entity(player:get_pos(), "hangglider:glider"):set_attach(player, "", {x=0,y=10,z=0}, {x=0,y=0,z=0})
					else  -- minetest 0.4.x, no offset needed
						minetest.add_entity(player:get_pos(), "hangglider:glider"):set_attach(player, "", {x=0,y=0,z=0}, {x=0,y=0,z=0})
					end
					itemstack:add_wear(wear_incr)
					player:set_wielded_item(itemstack)
				elseif minetest.get_node(pos).name == "air" and hangglider.use[pname] then --Unequip
					if HUD_Overlay then player:hud_change(hangglider.id[pname], "text", "") end
					hangglider.use[pname] = false
					if itemstack:get_wear() + wear_incr > 65535 then
						player:set_wielded_item(nil)
						minetest.sound_play("default_tool_breaks", {pos=pos, max_hear_distance = 8, gain = 1.0})
					end
				end
			end
			prev_equip_key[pname] = current_equip_key
		else -- not wielding hangglider
			if hangglider.use[pname] then --Unequip
				if HUD_Overlay then player:hud_change(hangglider.id[pname], "text", "") end
				hangglider.use[pname] = false
				if itemstack:get_wear() + wear_incr > 65535 then
					player:set_wielded_item(nil)
					minetest.sound_play("default_tool_breaks", {pos=pos, max_hear_distance = 8, gain = 1.0})
				end
			end
		end
	end
end)

minetest.register_craft({
	output = "hangglider:hangglider",
	recipe = {
		{"wool:white", "wool:white", "wool:white"},
		{"default:stick", "", "default:stick"},
		{"", "default:stick", ""},
	}
})
