local RESOURCE_UI = "esx_textui"

---@type BridgeLib.UI.Client
local provider = {
	ShowTextUI = function(text)
		exports[RESOURCE_UI]:TextUI(text)
	end,

	HideTextUI = function()
		exports[RESOURCE_UI]:HideUI()
	end,
}

return provider
