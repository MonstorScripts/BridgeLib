local RESOURCE_UI = "jg-textui"

---@type BridgeLib.UI.Client
local provider = {
	ShowTextUI = function(text)
		exports[RESOURCE_UI]:DrawText(text)
	end,

	HideTextUI = function()
		exports[RESOURCE_UI]:HideText()
	end,
}

return provider
