---Society accounts, addressed by job name. Providers prefix them the way their resource expects.
---@class BridgeLib.Society.Server
local schema = {
	---@param jobName string
	---@return number balance 0 when the society has no account.
	GetSocietyMoney = function(jobName) end,

	---@param jobName string
	---@param amount number
	---@param reason string? Ignored by providers that keep no transaction log.
	---@return boolean deposited false when the society has no account.
	AddSocietyMoney = function(jobName, amount, reason) end,

	---@param jobName string
	---@param amount number
	---@param reason string? Ignored by providers that keep no transaction log.
	---@return boolean withdrawn false when the society has no account or too little money.
	RemoveSocietyMoney = function(jobName, amount, reason) end,
}

---@type BridgeLib.Module
return {
	name = "society",
	context = "server",
	providers = {
		"esx_addonaccount",
		"qb-management",
		"Renewed-Banking",
		"qb-banking",
		"okokBanking",
		"snipe-banking",
		"tgiann-bank",
		"kartik-banking",
	},
	required = {
		"GetSocietyMoney",
		"AddSocietyMoney",
		"RemoveSocietyMoney",
	},
	schema = schema,
}
