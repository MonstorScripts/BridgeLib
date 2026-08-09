---Every minigame, as the resource that provides it and a function that runs it. Some resources
---report their result through a callback and some return it, so each entry ends up calling `cb`
---itself rather than the caller having to know which.
---@type table<string, { resource: string, start: fun(cb: fun(success: boolean), ...) }>
local games = {}

---@param resource string
---@return boolean
local function isRunning(resource)
	local state = GetResourceState(resource)
	return state == "started" or state == "starting"
end

---@param kind string
---@param resource string
---@param start fun(cb: fun(success: boolean), ...)
local function register(kind, resource, start)
	games[kind] = { resource = resource, start = start }
end

---Wraps a minigame that returns its result rather than calling back.
---@param resource string
---@param method string
---@return fun(cb: fun(success: boolean), ...)
local function returning(resource, method)
	return function(cb, ...)
		cb(exports[resource][method](exports[resource], ...) and true or false)
	end
end

---Wraps a minigame that already takes the callback as its first argument.
---@param resource string
---@param method string
---@return fun(cb: fun(success: boolean), ...)
local function callingBack(resource, method)
	return function(cb, ...)
		exports[resource][method](exports[resource], cb, ...)
	end
end

for _, method in ipairs({ "Circle", "Maze", "VarHack", "Thermite", "Scrambler" }) do
	register("ps-" .. method:lower(), "ps-ui", callingBack("ps-ui", method))
end

register("memorygame-thermite", "memorygame", function(cb, correctBlocks, incorrectBlocks, timeToShow, timeToLose)
	exports["memorygame"]:thermiteminigame(correctBlocks, incorrectBlocks, timeToShow, timeToLose, function()
		cb(true)
	end, function()
		cb(false)
	end)
end)

register("utk-fingerprint", "utk_fingerprint", function(cb, circles, matches, time)
	TriggerEvent("utk_fingerprint:Start", circles or 1, matches or 6, time or 1, function(outcome)
		cb(outcome == true)
	end)
end)

register("m-drilling", "M-drilling", function(cb)
	TriggerEvent("Drilling:Start", function(success)
		cb(success == true)
	end)
end)

register("hacking-opengame", "hacking", function(cb, duration, length, amount)
	exports["hacking"]:OpenHackingGame(duration, length, amount, cb)
end)

register("ran-memorycard", "ran-minigames", returning("ran-minigames", "MemoryCard"))
register("ran-openterminal", "ran-minigames", returning("ran-minigames", "OpenTerminal"))
register("howdy-begin", "howdy-hackminigame", returning("howdy-hackminigame", "Begin"))

register("sn-memorygame", "SN-Hacking", returning("SN-Hacking", "MemoryGame"))
register("sn-skillcheck", "SN-Hacking", returning("SN-Hacking", "SkillCheck"))
register("sn-thermite", "SN-Hacking", returning("SN-Hacking", "Thermite"))
register("sn-keypad", "SN-Hacking", returning("SN-Hacking", "KeyPad"))
register("sn-colorpicker", "SN-Hacking", returning("SN-Hacking", "ColorPicker"))

for kind, method in pairs({
	["rm-typinggame"] = "typingGame",
	["rm-timedlockpick"] = "timedLockpick",
	["rm-timedaction"] = "timedAction",
	["rm-quicktimeevent"] = "quickTimeEvent",
	["rm-combinationlock"] = "combinationLock",
	["rm-buttonmashing"] = "buttonMashing",
	["rm-angledlockpick"] = "angledLockpick",
	["rm-fingerprint"] = "fingerPrint",
	["rm-circleclick"] = "circleClick",
	["rm-hotwirehack"] = "hotwireHack",
	["rm-hackerminigame"] = "hackerMinigame",
	["rm-safecrack"] = "safeCrack",
}) do
	register(kind, "rm_minigames", returning("rm_minigames", method))
end

for kind, method in pairs({
	["bl-circlesum"] = "CircleSum",
	["bl-digitdazzle"] = "DigitDazzle",
	["bl-lightsout"] = "LightsOut",
	["bl-minesweeper"] = "MineSweeper",
	["bl-pathfind"] = "PathFind",
	["bl-printlock"] = "PrintLock",
	["bl-untangle"] = "Untangle",
	["bl-wavematch"] = "WaveMatch",
	["bl-wordwiz"] = "WordWiz",
}) do
	register(kind, "bl_ui", returning("bl_ui", method))
end

for kind, method in pairs({
	["gl-firewall-pulse"] = "StartFirewallPulse",
	["gl-backdoor-sequence"] = "StartBackdoorSequence",
	["gl-circuit-rhythm"] = "StartCircuitRhythm",
	["gl-surge-override"] = "StartSurgeOverride",
	["gl-circuit-breaker"] = "StartCircuitBreaker",
	["gl-data-crack"] = "StartDataCrack",
	["gl-brute-force"] = "StartBruteForce",
	["gl-var-hack"] = "StartVarHack",
}) do
	register(kind, "glitch-minigames", returning("glitch-minigames", method))
end

---@param bridge BridgeLib.Bridge
---@return BridgeLib.Minigames.Client
return function(bridge)
	return {
		GetHacks = function()
			local kinds = {}
			for kind in pairs(games) do
				kinds[#kinds + 1] = kind
			end
			table.sort(kinds)
			return kinds
		end,

		HasHack = function(kind)
			local game = games[kind]
			return game ~= nil and isRunning(game.resource)
		end,

		StartHack = function(kind, callback, ...)
			local game = games[kind]

			if not game then
				bridge:Debug(("No minigame is named '%s'"):format(tostring(kind)))
				return callback(false)
			end

			if not isRunning(game.resource) then
				bridge:Debug(("Minigame '%s' needs '%s', which is not running"):format(kind, game.resource))
				return callback(false)
			end

			game.start(callback, ...)
		end,
	}
end
