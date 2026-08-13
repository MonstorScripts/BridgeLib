---@class BridgeLib.UI.TextOptions
---@field position string? Where on screen the text sits, e.g. "right-center".
---@field icon string? Font Awesome class, for the providers that draw one.

---Optional module: with no UI resource running, notifications and text are dropped and every
---progress bar reports itself as cancelled.
---
---Progress bars here block until the player finishes or cancels. The `framework` module's own
---`Progressbar` is the callback shaped alternative, and is the one to use on a server whose only UI
---resource is its framework.
---@class BridgeLib.UI.Client
local schema = {
	---@param message string
	---@param type string? One of "success", "error" or "inform", defaulting to "inform".
	Notify = function(message, type) end,

	---Blocking.
	---@param label string
	---@param duration number Milliseconds.
	---@param canCancel boolean?
	---@return boolean completed False when the player cancelled it.
	ProgressBar = function(label, duration, canCancel)
		return false
	end,

	---Draws persistent text until `HideTextUI`, replacing whatever is already on screen.
	---@param text string
	---@param options BridgeLib.UI.TextOptions?
	ShowTextUI = function(text, options) end,

	HideTextUI = function() end,
}

---@type BridgeLib.Module
return {
	name = "ui",
	context = "client",
	providers = {
		"lation_ui",
		"ox_lib",
		"cd_drawtextui",
		"qb-core",
		"esx_progressbar",
		"jg-textui",
		"esx_textui",
		"brutal_textui",
		"esx_notify",
		"okokNotify",
		"wasabi_notify",
		"brutal_notify",
		"mythic_notify",
	},
	schema = schema,
}
