local RESOURCE_TARGET = "ox_target"

---@type BridgeLib.Target.Client
local provider = {
	AddBoxZone = function(name, coords, width, length, options, targetOptions)
		local data = {
			name = name,
			coords = coords,
			size = vector3(width, length, options.maxZ - options.minZ),
			debug = options.debugPoly,
			options = targetOptions and targetOptions.options or {},
		}
		return exports[RESOURCE_TARGET]:addBoxZone(data)
	end,

	RemoveZone = function(...)
		return exports[RESOURCE_TARGET]:removeZone(...)
	end,

	AddTargetEntity = function(entity, options)
		local oxOptions = {}
		for ind, opt in pairs(options.options) do
			if type(opt) == "table" then
				local entry = {
					label = opt.label,
					icon = opt.icon,
					distance = opt.distance or options.distance or 2.5,
					onSelect = opt.action,
					canInteract = opt.canInteract,
					groups = opt.job,
					items = opt.item,
				}

				for k, v in pairs(entry) do
					if v == nil then
						entry[k] = nil
					end
				end

				oxOptions[#oxOptions + 1] = entry
			end
		end

		return exports[RESOURCE_TARGET]:addLocalEntity(entity, oxOptions)
	end,

	RemoveTargetEntity = function(entity)
		return exports[RESOURCE_TARGET]:removeLocalEntity(entity)
	end,
}

return provider
