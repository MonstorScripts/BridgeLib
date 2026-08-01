local RESOURCE_BOSSMENU = "al-bossmenu"

---@type BridgeLib.BossMenu.Client
local provider = {
	OpenBossMenu = function(jobName)
		return exports[RESOURCE_BOSSMENU]:OpenBossMenu(jobName)
	end,
}

return provider
