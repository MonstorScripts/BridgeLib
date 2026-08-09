---Both `gks-phone` and `gksphone` serve their exports under this name.
local RESOURCE_PHONE = "gksphone"

---@type BridgeLib.Email.Client
local provider = {
	SendEmail = function(sender, subject, message)
		exports[RESOURCE_PHONE]:SendNewMail({
			sender = sender,
			image = "/html/static/img/icons/mail.png",
			subject = subject,
			message = message,
		})
	end,
}

return provider
