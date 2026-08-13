local RESOURCE_PHONE = "yseries"

---yseries shows the display name rather than the address, but still wants an address to send from.
local SENDER_ADDRESS = "no-reply@bridgelib"

---@type BridgeLib.Email.Server
local provider = {
	SendEmail = function(src, sender, subject, message)
		exports[RESOURCE_PHONE]:SendMail({
			title = subject,
			sender = SENDER_ADDRESS,
			senderDisplayName = sender,
			content = message,
			actions = {},
			attachments = {},
		}, "source", src)
	end,
}

return provider
