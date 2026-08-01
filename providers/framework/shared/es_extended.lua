local function ImportESX()
	if not ESX then
		ESX = exports["es_extended"]:getSharedObject()
	end
end

---@type BridgeLib.Framework.Shared
local provider = {
	GetItemDisplayName = function(item)
		ImportESX()
		return ESX.GetItemLabel and ESX.GetItemLabel(item) or item
	end,
	GetJobName = function(name)
		ImportESX()
		local job = name:lower()
		local jobs = ESX.GetJobs and ESX.GetJobs() or {}

		for jobName, jobData in pairs(jobs) do
			if jobName:lower() == job then
				return jobData.label
			end
		end
		return name
	end,
}

return provider
