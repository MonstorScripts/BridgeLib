local RESOURCE_ZONES = "PolyZone"

---@param zone table
---@return BridgeLib.Zones.Zone
local function wrap(zone)
	return {
		id = zone,
		resource = RESOURCE_ZONES,
		remove = function(self)
			self.id:destroy()
		end,
	}
end

---@param zone table
---@param options BridgeLib.Zones.Options
---@return BridgeLib.Zones.Zone
local function bind(zone, options)
	if options.onPlayerInOut then
		zone:onPlayerInOut(options.onPlayerInOut)
	end
	return wrap(zone)
end

return function(bridge)
	if not PolyZone or not CircleZone then
		bridge:Fatal("PolyZone is running but its scripts are not loaded, add '@PolyZone/client.lua' and '@PolyZone/CircleZone.lua' to your shared_scripts")
	end

	---@type BridgeLib.Zones.Client
	local provider = {
		AddPolyZone = function(points, options)
			options = options or {}

			local zone = PolyZone:Create(points, {
				name = options.name,
				minZ = options.minZ,
				maxZ = options.maxZ,
				debugPoly = options.debug,
			})

			return bind(zone, options)
		end,

		AddCircleZone = function(coords, radius, options)
			options = options or {}

			local zone = CircleZone:Create(coords, radius, {
				name = options.name,
				debugPoly = options.debug,
			})

			return bind(zone, options)
		end,

		DestroyZone = function(zone)
			if type(zone) == "table" and zone.remove then
				zone:remove()
			end
		end,
	}

	return provider
end
