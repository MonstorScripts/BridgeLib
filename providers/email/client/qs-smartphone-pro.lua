---@type BridgeLib.Email.Client
local provider = {
	SendEmail = function(sender, subject, message)
		TriggerServerEvent("phone:sendNewMail", {
			sender = sender,
			subject = subject,
			message = message,
		})
	end,
}

return provider
