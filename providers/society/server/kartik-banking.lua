local RESOURCE_SOCIETY = "kartik-banking"

---@type BridgeLib.Society.Server
local provider = {
	GetSocietyMoney = function(jobName)
		return exports[RESOURCE_SOCIETY]:GetAccountMoney(jobName) or 0
	end,

	AddSocietyMoney = function(jobName, amount)
		exports[RESOURCE_SOCIETY]:AddAccountMoney(jobName, amount)
		return true
	end,

	RemoveSocietyMoney = function(jobName, amount)
		return exports[RESOURCE_SOCIETY]:RemoveAccountMoney(jobName, amount) and true or false
	end,
}

return provider
