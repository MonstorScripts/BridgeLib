local RESOURCE_CORE = "qb-core"

local GetCoreObject = function()
	return exports[RESOURCE_CORE]:GetCoreObject()
end

---@return BridgeLib.Framework.Shared
return {
	GetItemDisplayName = function(item)
		local QBCore = GetCoreObject()
		return (QBCore.Shared.Items[item:lower()] or { label = "ERROR_UNKNOWN_ITEM" }).label
	end,
	GetJobName = function(name)
		local QBCore = GetCoreObject()
		return (QBCore.Shared.Jobs[name:lower()] or { label = "ERROR_UNKNOWN_JOB" }).label
	end,
}
