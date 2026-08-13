local RESOURCE_PHONE = "lb-phone"

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Email.Server
return function(bridge)
	return {
		SendEmail = function(src, sender, subject, message)
			local number = exports[RESOURCE_PHONE]:GetEquippedPhoneNumber(src)
			local address = number and exports[RESOURCE_PHONE]:GetEmailAddress(number)

			if not address then
				bridge:Debug(("Player %s carries no lb-phone with an email address"):format(tostring(src)))
				return
			end

			exports[RESOURCE_PHONE]:SendMail({
				to = address,
				sender = sender,
				subject = subject,
				message = message,
			})
		end,
	}
end
