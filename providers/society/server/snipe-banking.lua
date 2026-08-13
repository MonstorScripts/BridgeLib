local RESOURCE_SOCIETY = "snipe-banking"

---@type BridgeLib.Society.Server
local provider = {
	GetSocietyMoney = function(jobName)
		return exports[RESOURCE_SOCIETY]:GetAccountBalance(jobName) or 0
	end,

	AddSocietyMoney = function(jobName, amount)
		exports[RESOURCE_SOCIETY]:AddMoneyToAccount(jobName, amount)
		return true
	end,

	RemoveSocietyMoney = function(jobName, amount)
		return exports[RESOURCE_SOCIETY]:RemoveMoneyFromAccount(jobName, amount) and true or false
	end,
}

return provider
