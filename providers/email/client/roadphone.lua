local RESOURCE_PHONE = "roadphone"

---@type BridgeLib.Email.Client
local provider = {
	SendEmail = function(sender, subject, message)
		exports[RESOURCE_PHONE]:sendMail({
			sender = sender,
			subject = subject,
			message = message,
		})
	end,
}

return provider
