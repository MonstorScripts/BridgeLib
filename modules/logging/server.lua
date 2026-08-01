---Structured logging to Discord, posted by the library itself rather than through a framework.
---
---A category names one destination. Its URL is resolved, in order, from `SetWebhookUrl`, the
---`bridgelib_webhook_<category>` convar, then the `bridgelib_webhook_default` convar. A category
---that resolves to no URL is dropped, so a server that configures nothing logs nothing.
---
---`bridgelib_webhook_username`, `bridgelib_webhook_avatar` and `bridgelib_webhook_footer` decorate
---every payload when they are set.
---
---This module defines `LogFields` under the same signature as the framework module's, so a consumer
---that declares both must declare `logging` after `framework` for these implementations to win.

---One field of a Discord embed. `value` is stringified and truncated by the provider.
---@class BridgeLib.Logging.Field
---@field name string
---@field value any
---@field inline boolean?

---@class BridgeLib.Logging.Server
local schema = {
	---Overrides a category's webhook URL for the lifetime of the resource, ahead of any convar.
	---@param category string
	---@param url string? Passing nil clears the override and falls back to the convars.
	SetWebhookUrl = function(category, url) end,

	---The URL a category currently resolves to.
	---@param category string
	---@return string? url nil when neither an override nor a convar supplies one.
	GetWebhookUrl = function(category) end,

	---Queues an embed built from a list of fields.
	---@param category string
	---@param title string
	---@param colour string|number? Decimal colour, as Discord embeds take it.
	---@param fields BridgeLib.Logging.Field[]?
	LogFields = function(category, title, colour, fields) end,

	---Queues an embed carrying a body of text rather than fields.
	---@param category string
	---@param message string
	---@param title string?
	---@param colour string|number?
	LogMessage = function(category, message, title, colour) end,

	---Queues a payload the caller composed itself, for anything the helpers do not cover.
	---@param category string
	---@param payload table Discord webhook payload, sent as-is apart from the shared decorations.
	SendWebhook = function(category, payload) end,
}

---@type BridgeLib.Module
return {
	name = "logging",
	context = "server",
	providers = {
		"BridgeLib",
	},
	required = {
		"SetWebhookUrl",
		"GetWebhookUrl",
		"LogFields",
		"LogMessage",
		"SendWebhook",
	},
	schema = schema,
}
