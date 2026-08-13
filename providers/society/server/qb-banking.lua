local RESOURCE_SOCIETY = "qb-banking"

---@type BridgeLib.Society.Server
local provider = {
	GetSocietyMoney = function(jobName)
		return exports[RESOURCE_SOCIETY]:GetAccountBalance(jobName) or 0
	end,

	AddSocietyMoney = function(jobName, amount, reason)
		exports[RESOURCE_SOCIETY]:AddMoney(jobName, amount, reason)
		return true
	end,

	RemoveSocietyMoney = function(jobName, amount, reason)
		return exports[RESOURCE_SOCIETY]:RemoveMoney(jobName, amount, reason) and true or false
	end,
}

return provider
