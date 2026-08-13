local RESOURCE_MULTIJOB = "monstor-multijob"

---@type BridgeLib.Multijob.Server
local provider = {
	GetPlayersInJob = function(jobName, shouldCheckOffline)
		return exports[RESOURCE_MULTIJOB]:ReturnPlayersInJob(jobName, shouldCheckOffline) or {}
	end,

	IsPlayerInJob = function(identifier, jobName)
		return exports[RESOURCE_MULTIJOB]:IsPlayerInJob(identifier, jobName)
	end,

	SetPlayerJob = function(identifier, jobData)
		return exports[RESOURCE_MULTIJOB]:SetPlayerJob(identifier, jobData) and true or false
	end,

	RemovePlayerJob = function(identifier, jobName)
		return exports[RESOURCE_MULTIJOB]:RemoveJob(identifier, jobName)
	end,
}

return provider
