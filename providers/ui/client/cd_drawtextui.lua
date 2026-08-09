---@type BridgeLib.UI.Client
local provider = {
	ShowTextUI = function(text)
		TriggerEvent("cd_drawtextui:ShowUI", "show", text)
	end,

	HideTextUI = function()
		TriggerEvent("cd_drawtextui:HideUI")
	end,
}

return provider
