local RESOURCE_TARGET = "ox_target"

---@param options BridgeLib.Target.Option[]?
---@param defaultDistance number?
---@return table
local function toOxOptions(options, defaultDistance)
	local oxOptions = {}

	for _, opt in pairs(options or {}) do
		if type(opt) == "table" then
			local entry = {
				name = opt.name,
				label = opt.label,
				icon = opt.icon,
				distance = opt.distance or defaultDistance or 2.5,
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

	return oxOptions
end

---@type BridgeLib.Target.Client
local provider = {
	AddBoxZone = function(name, coords, width, length, options, targetOptions)
		local data = {
			name = name,
			coords = coords,
			size = vector3(width, length, options.maxZ - options.minZ),
			rotation = options.heading or 0,
			debug = options.debugPoly,
			options = toOxOptions(targetOptions and targetOptions.options, targetOptions and targetOptions.distance),
		}
		return exports[RESOURCE_TARGET]:addBoxZone(data)
	end,

	RemoveZone = function(...)
		return exports[RESOURCE_TARGET]:removeZone(...)
	end,

	AddTargetEntity = function(entity, options)
		return exports[RESOURCE_TARGET]:addLocalEntity(entity, toOxOptions(options.options, options.distance))
	end,

	RemoveTargetEntity = function(entity)
		return exports[RESOURCE_TARGET]:removeLocalEntity(entity)
	end,
}

return provider
