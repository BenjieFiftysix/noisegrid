-- noisegrid 0.2.1 by paramat
-- For latest stable Minetest and back to 0.4.8
-- Depends default
-- License: code WTFPL

-- Add dirt, sand, stone

-- Parameters

local YVAL = 5
local YSAND = 3
local TERSCA = 128
local TROAD = 0.1
local TVAL = 0.11

-- 2D noise for base terrain

local np_base = {
	offset = 0,
	scale = 1,
	spread = {x=2048, y=2048, z=2048},
	seed = -9111,
	octaves = 6,
	persist = 0.6
}

-- Stuff

noisegrid = {}

-- Nodes

minetest.register_node("noisegrid:grass", {
	description = "Grass",
	tiles = {"default_grass.png", "default_dirt.png", "default_grass.png"},
	is_ground_content = false,
	groups = {crumbly=3,soil=1},
	drop = "default:dirt",
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_grass_footstep", gain=0.25},
	}),
})

minetest.register_node("noisegrid:dirt", {
	description = "Dirt",
	tiles = {"default_dirt.png"},
	is_ground_content = false,
	groups = {crumbly=3,soil=1},
	drop = "default:dirt",
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_node("noisegrid:stone", {
	description = "Stone",
	tiles = {"default_stone.png"},
	groups = {cracky=3},
	drop = "default:cobble",
	sounds = default.node_sound_stone_defaults(),
})

-- Set mapgen parameters

minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_params({mgname="singlenode"})
end)

-- Spawn player

function spawnplayer(player)
	player:setpos({x=0, y=2, z=0})
end

minetest.register_on_newplayer(function(player)
	spawnplayer(player)
end)

minetest.register_on_respawnplayer(function(player)
	spawnplayer(player)
	return true
end)

-- On generated function

minetest.register_on_generated(function(minp, maxp, seed)
	if minp.y < -192 or minp.y > 128 then
		return
	end

	local t1 = os.clock()
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z
	
	print ("[noisegrid] chunk minp ("..x0.." "..y0.." "..z0..")")
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	
	local c_grass = minetest.get_content_id("noisegrid:grass")
	local c_dirt = minetest.get_content_id("noisegrid:dirt")
	local c_stone = minetest.get_content_id("noisegrid:stone")
	local c_water = minetest.get_content_id("default:water_source")
	local c_sand = minetest.get_content_id("default:sand")
	local c_wblack = minetest.get_content_id("wool:black")
	local c_wwhite = minetest.get_content_id("wool:white")
	
	local sidelen = x1 - x0 + 1
	local chulens = {x=sidelen, y=sidelen, z=sidelen}
	local minposxz = {x=x0, y=z0}
	
	local nvals_base = minetest.get_perlin_map(np_base, chulens):get2dMap_flat(minposxz)
	
	local cross = false
	local nroad = false
	local eroad = false
	local sroad = false
	local wroad = false
	if math.abs(nvals_base[6359]) < TROAD then
		nroad = true
	end
	if math.abs(nvals_base[3121]) < TROAD then
		wroad = true
	end
	if math.abs(nvals_base[3160]) < TROAD then
		cross = true
	end
	if math.abs(nvals_base[3200]) < TROAD then
		eroad = true
	end
	if math.abs(nvals_base[39]) < TROAD then
		sroad = true
	end
	
	local nixz = 1
	for z = z0, z1 do
		for y = y0, y1 do
			local vi = area:index(x0, y, z)
			for x = x0, x1 do
				local xr = x - x0
				local zr = z - z0
				local ysurf
				local n_base = nvals_base[nixz]
				local n_absbase = math.abs(n_base)
				if n_base > TVAL then
					ysurf = YVAL + math.floor((n_base - TVAL) * TERSCA)
				elseif n_base < -TVAL then
					ysurf = YVAL - math.floor((-TVAL - n_base) * TERSCA)
				else
					ysurf = YVAL
				end
				
				if y == YVAL and n_absbase <= TVAL then
					if xr >= 36 and xr <= 42 and zr >= 36 and zr <= 42 -- centre
					and (nroad or eroad or sroad or wroad) and cross then
						data[vi] = c_wblack
					elseif xr >= 36 and xr <= 42 and zr >= 43 -- north
					and nroad and cross then
						if xr == 39 then
							data[vi] = c_wwhite
						else
							data[vi] = c_wblack
						end
					elseif xr >= 43 and zr >= 36 and zr <= 42 -- east
					and eroad and cross then
						if zr == 39 then
							data[vi] = c_wwhite
						else
							data[vi] = c_wblack
						end
					elseif xr >= 36 and xr <= 42 and zr <= 35 -- south
					and sroad and cross then
						if xr == 39 then
							data[vi] = c_wwhite
						else
							data[vi] = c_wblack
						end
					elseif xr <= 35 and zr >= 36 and zr <= 42 -- west
					and wroad and cross then
						if zr == 39 then
							data[vi] = c_wwhite
						else
							data[vi] = c_wblack
						end
					else
						data[vi] = c_grass
					end
				elseif y < ysurf - 3 then
					data[vi] = c_stone
				elseif y <= ysurf and y <= YSAND then
					data[vi] = c_sand
				elseif y == ysurf then
					data[vi] = c_grass
				elseif y < ysurf then
					data[vi] = c_dirt
				elseif y <= 1 then
					data[vi] = c_water
				end
				nixz = nixz + 1
				vi = vi + 1
			end
			nixz = nixz - 80
		end
		nixz = nixz + 80
	end
	
	vm:set_data(data)
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map(data)
	local chugent = math.ceil((os.clock() - t1) * 1000)
	print ("[noisegrid] "..chugent.." ms")
end)