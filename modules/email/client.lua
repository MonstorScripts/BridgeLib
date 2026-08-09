---Optional module: with no phone running, emails are dropped.
---
---lb-phone, high-phone, yseries, yflip-phone and okokPhone all address the mailbox from the server,
---so they appear only in the server context. A client on one of those calls the server bridge instead.
---@class BridgeLib.Email.Client
local schema = {
	---Sends an email to the local player's own mailbox.
	---@param sender string Display name the email arrives from.
	---@param subject string
	---@param message string
	SendEmail = function(sender, subject, message) end,
}

---@type BridgeLib.Module
return {
	name = "email",
	context = "client",
	providers = {
		"qb-phone",
		"qs-smartphone-pro",
		"qs-smartphone",
		"gksphone",
		{ resource = "gks-phone", adapter = "gksphone" },
		"roadphone",
		"npwd",
		{ resource = "npwd-phone", adapter = "npwd" },
	},
	required = {
		"SendEmail",
	},
	schema = schema,
}
