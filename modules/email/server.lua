---Optional module: with no phone running, emails are dropped.
---
---npwd owns no mailbox of its own, so its entries name the mail app running alongside it rather than
---the phone.
---@class BridgeLib.Email.Server
local schema = {
	---Sends an email to one player's own mailbox.
	---@param src number
	---@param sender string Display name the email arrives from.
	---@param subject string
	---@param message string
	SendEmail = function(src, sender, subject, message) end,
}

---@type BridgeLib.Module
return {
	name = "email",
	context = "server",
	providers = {
		"lb-phone",
		"high-phone",
		"yseries",
		"yflip-phone",
		"okokPhone",
		{ resource = "npwd_qbx_mail", adapter = "npwd" },
		{ resource = "npwd_qb_mail", adapter = "npwd" },
	},
	required = {
		"SendEmail",
	},
	schema = schema,
}
