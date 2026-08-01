local RESOURCE_MULTIJOB = "al-multijob"

---@type BridgeLib.Multijob.Server
local provider = {
	GetPlayersInJob = function(jobName)
		return exports[RESOURCE_MULTIJOB]:ReturnPlayersInJob(jobName) or {}
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
