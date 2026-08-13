local RESOURCE_UI = "brutal_textui"

---@type BridgeLib.UI.Client
local provider = {
	ShowTextUI = function(text)
		exports[RESOURCE_UI]:Open(text, "blue")
	end,

	HideTextUI = function()
		exports[RESOURCE_UI]:Close()
	end,
}

return provider
