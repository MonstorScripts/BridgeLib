local RESOURCE_PHONE = "npwd"

---npwd ships no mail app, so the inbox comes from one of the community apps running alongside it.
---Both keep qb-phone's event names, and this one reads `source`, so it lands in the sender's own
---mailbox.
local MAIL_RESOURCES = { "npwd_qbx_mail", "npwd_qb_mail" }

local EVENT_SEND_MAIL = "qb-phone:server:sendNewMail"

---Milliseconds npwd keeps the notification on screen for.
local NOTIFICATION_DURATION = 5000

---@return boolean
local function hasMailApp()
	for _, resource in ipairs(MAIL_RESOURCES) do
		local state = GetResourceState(resource)
		if state == "started" or state == "starting" then
			return true
		end
	end

	return false
end

---With a mail app installed the email is stored and shown in its inbox. Without one npwd has no
---mailbox at all, so the email arrives as a notification into its email app instead.
---@type BridgeLib.Email.Client
local provider = {
	SendEmail = function(sender, subject, message)
		if hasMailApp() then
			TriggerServerEvent(EVENT_SEND_MAIL, {
				sender = sender,
				subject = subject,
				message = message,
			})
			return
		end

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
