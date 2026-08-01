local RESOURCE_SOCIETY = "esx_addonaccount"

---@param jobName string
---@return table? account
local function getAccount(jobName)
	return exports[RESOURCE_SOCIETY]:GetSharedAccount("society_" .. jobName)
end

---@type BridgeLib.Society.Server
local provider = {
	GetSocietyMoney = function(jobName)
		local account = getAccount(jobName)
		return account and account.money or 0
	end,

	AddSocietyMoney = function(jobName, amount)
		local account = getAccount(jobName)
		if not account then
			return false
		end

		account.addMoney(amount)
		return true
	end,

	RemoveSocietyMoney = function(jobName, amount)
		local account = getAccount(jobName)
		if not account or account.money < amount then
			return false
		end

		account.removeMoney(amount)
		return true
	end,
}

return provider
