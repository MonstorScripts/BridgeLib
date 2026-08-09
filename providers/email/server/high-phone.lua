local RESOURCE_PHONE = "high-phone"

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Email.Server
return function(bridge)
	return {
		SendEmail = function(src, sender, subject, message)
			local account = exports[RESOURCE_PHONE]:getPlayerMailAccount(src)

			if not account or not account.address then
				bridge:Debug(("Player %s holds no high-phone mail account"):format(tostring(src)))
				return
			end

			exports[RESOURCE_PHONE]:sendMail({
				sender = sender,
				recipients = { account.address },
				subject = subject,
				content = message,
				attachments = {},
			})
		end,
	}
end
