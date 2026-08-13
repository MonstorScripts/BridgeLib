local RESOURCE_SOCIETY = "okokBanking"

---@type BridgeLib.Society.Server
local provider = {
	GetSocietyMoney = function(jobName)
		return exports[RESOURCE_SOCIETY]:GetAccount(jobName) or 0
	end,

	AddSocietyMoney = function(jobName, amount)
		exports[RESOURCE_SOCIETY]:AddMoney(jobName, amount)
		return true
	end,

	RemoveSocietyMoney = function(jobName, amount)
		return exports[RESOURCE_SOCIETY]:RemoveMoney(jobName, amount) and true or false
	end,
}

return provider
