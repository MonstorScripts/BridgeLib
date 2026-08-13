---npwd itself ships no mailbox, so the mail app that runs alongside it owns the inbox. Both of the
---community apps keep qb-phone's event names, and the offline variant is the only one that names a
---recipient rather than reading `source`, so it is what a server side send has to use. It stores the
---mail and pushes it to the player when they are connected.
local EVENT_SEND_MAIL = "qb-phone:server:sendNewMailToOffline"

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Email.Server
return function(bridge)
	return {
		---The mail app addresses a mailbox by character identifier, so this needs the `framework`
		---module on the same bridge.
		SendEmail = function(src, sender, subject, message)
			local getPlayer = bridge.exports.GetPlayer
			local player = type(getPlayer) == "function" and getPlayer(src)

			if not player or not player.UniqueId then
				bridge:Debug(("No framework player for %s, so the npwd mail app has no mailbox to reach"):format(tostring(src)))
				return
			end

			TriggerEvent(EVENT_SEND_MAIL, player.UniqueId, {
				sender = sender,
				subject = subject,
				message = message,
			})
		end,
	}
end
