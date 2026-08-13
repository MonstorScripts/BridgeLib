local RESOURCE_PHONE = "okokPhone"

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Email.Server
return function(bridge)
	return {
		SendEmail = function(src, sender, subject, message)
			local address = exports[RESOURCE_PHONE]:getEmailAddressFromSource(src)

			if not address then
				bridge:Debug(("Player %s holds no okokPhone email address"):format(tostring(src)))
				return
			end

			exports[RESOURCE_PHONE]:sendEmail({
				sender = sender,
				recipients = { address },
				subject = subject,
				body = message,
			})
		end,
	}
end
