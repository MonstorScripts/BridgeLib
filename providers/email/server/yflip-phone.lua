local RESOURCE_PHONE = "yflip-phone"

---yflip-phone shows the display name rather than the address, but still wants an address to send from.
local SENDER_ADDRESS = "no-reply@bridgelib"

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Email.Server
return function(bridge)
	return {
		---yflip-phone addresses a mailbox by phone number, which it maps from the framework identifier,
		---so this needs the `framework` module on the same bridge.
		SendEmail = function(src, sender, subject, message)
			local getPlayer = bridge.exports.GetPlayer
			local player = type(getPlayer) == "function" and getPlayer(src)

			if not player or not player.UniqueId then
				bridge:Debug(("No framework player for %s, so yflip-phone has no mailbox to reach"):format(tostring(src)))
				return
			end

			local number = exports[RESOURCE_PHONE]:GetPhoneNumberByIdentifier(player.UniqueId)
			if not number then
				bridge:Debug(("Player %s owns no yflip-phone number"):format(tostring(src)))
				return
			end

			exports[RESOURCE_PHONE]:SendMail({
				title = subject,
				sender = SENDER_ADDRESS,
				senderDisplayName = sender,
				content = message,
			}, "phoneNumber", number)
		end,
	}
end
