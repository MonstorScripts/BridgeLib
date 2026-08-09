---@type BridgeLib.Email.Client
local provider = {
	SendEmail = function(sender, subject, message)
		TriggerServerEvent("qb-phone:server:sendNewMail", {
			sender = sender,
			subject = subject,
			message = message,
		})
	end,
}

return provider
