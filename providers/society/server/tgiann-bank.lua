local RESOURCE_SOCIETY = "tgiann-bank"

---@type BridgeLib.Society.Server
local provider = {
	GetSocietyMoney = function(jobName)
		return exports[RESOURCE_SOCIETY]:GetJobAccountBalance(jobName) or 0
	end,

	AddSocietyMoney = function(jobName, amount)
		exports[RESOURCE_SOCIETY]:AddJobMoney(jobName, amount)
		return true
	end,

	RemoveSocietyMoney = function(jobName, amount)
		return exports[RESOURCE_SOCIETY]:RemoveJobMoney(jobName, amount) and true or false
	end,
}

return provider
