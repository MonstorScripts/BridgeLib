local RESOURCE_SOCIETY = "Renewed-Banking"

---@type BridgeLib.Society.Server
local provider = {
	GetSocietyMoney = function(jobName)
		return exports[RESOURCE_SOCIETY]:getAccountMoney(jobName) or 0
	end,

	AddSocietyMoney = function(jobName, amount, reason)
		exports[RESOURCE_SOCIETY]:addAccountMoney(jobName, amount, reason)
		return true
	end,

	RemoveSocietyMoney = function(jobName, amount, reason)
		return exports[RESOURCE_SOCIETY]:removeAccountMoney(jobName, amount, reason) and true or false
	end,
}

return provider
