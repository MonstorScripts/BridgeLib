---@type BridgeLib.Email.Client
local provider = {
	SendEmail = function(sender, subject, message)
		TriggerServerEvent("qs-smartphone:server:sendNewMail", {
			sender = sender,
			subject = subject,
			message = message,
			button = {},
		})
	end,
}

return provider
