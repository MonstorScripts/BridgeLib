local RESOURCE_PHONE = "npwd"

---Milliseconds npwd keeps the notification on screen for.
local NOTIFICATION_DURATION = 5000

---npwd exposes no mailbox, so an email arrives as a notification into its email app instead.
---@type BridgeLib.Email.Client
local provider = {
	SendEmail = function(sender, subject, message)
		exports[RESOURCE_PHONE]:createNotification({
			notisId = "npwd:emailNotification",
			appId = "EMAIL",
			content = message,
			secondaryTitle = subject,
			keepOpen = false,
			duration = NOTIFICATION_DURATION,
			path = "/email",
		})
	end,
}

return provider
