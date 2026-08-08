---Translations layered shipped English, then the downloaded language, then the owner's `.local.json`.

---@class BridgeLib.Locales.Settings
---@field enabled boolean? Set to false to never contact the API, using only the files on disk.
---@field language string? Language to render in, defaulting to the shipped English.
---@field apiUrl string? Overrides the hosted API.
---@field delay number? Milliseconds to wait after startup before fetching.

local Locales = {}

Locales.ApiUrl = "https://versions.monstorscripts.com"

Locales.Delay = 5000

---The language every resource ships and the fallback for any key an overlay leaves untranslated.
Locales.SourceLanguage = "en"

---Carries the resource name, since every resource's handler sees every request.
Locales.RequestEvent = "BridgeLib:locales:request"

Locales.DeliverEvent = "BridgeLib:locales:deliver"

---GlobalState key, since a client cannot read `config.lua` to learn the language itself.
Locales.LanguageKey = "bridgeLibLocalesLanguage"

---Seconds between requests one player may make.
Locales.RequestCooldown = 5

---Milliseconds a client waits for the server's `GlobalState` to replicate before reading the language.
Locales.ReplicationDelay = 2000

---Flat strings per resource, keyed so a mismatched delivery is dropped rather than overwriting.
---@type table<string, table<string, string>>
Locales.strings = {}

---Owner overrides per resource, kept apart so a later fetch can be layered under them.
---@type table<string, table<string, string>>
Locales.overrides = {}

---Shipped English per resource, kept unmerged so a fetch can rebuild the table from the bottom up.
---@type table<string, table<string, string>>
Locales.source = {}

---Keyed by resource and context, so a resource building both bridges sets itself up once per context.
---@type table<string, boolean>
Locales.registered = {}

---@type table<number, number>
Locales.lastRequest = {}

---Nested locale table to flat dot paths, dropping any value that is neither a string nor a table.
---@param node table
---@param prefix string?
---@param out table<string, string>?
---@return table<string, string>
function Locales.Flatten(node, prefix, out)
	out = out or {}

	for key, value in pairs(node) do
		local path = prefix and ("%s.%s"):format(prefix, key) or tostring(key)

		if type(value) == "string" then
			out[path] = value
		elseif type(value) == "table" then
			Locales.Flatten(value, path, out)
		end
	end

	return out
end

---Reads one locale file out of the resource and flattens it; a missing or malformed file is nil.
---@param resourceName string
---@param path string
---@return table<string, string>?
function Locales.ReadFile(resourceName, path)
	local contents = LoadResourceFile(resourceName, path)
	if not contents then
		return nil
	end

	local success, decoded = pcall(json.decode, contents)
	if not success or type(decoded) ~= "table" then
		return nil
	end

	return Locales.Flatten(decoded)
end

---@param language string
---@return string
function Locales.CachePath(language)
	return ("locales/%s.json"):format(language)
end

---Nothing but the owner ever writes this file.
---@param language string
---@return string
function Locales.OverridePath(language)
	return ("locales/%s.local.json"):format(language)
end

---@param strings table<string, string>?
---@return number
function Locales.Count(strings)
	local total = 0

	for _ in pairs(strings or {}) do
		total = total + 1
	end

	return total
end

---@param strings table<string, string>
---@return table<string, string>
function Locales.Copy(strings)
	local copy = {}

	for key, value in pairs(strings) do
		copy[key] = value
	end

	return copy
end

---How many of `overlay`'s keys `base` already holds; the rest are keys nothing renders.
---@param base table<string, string>
---@param overlay table<string, string>?
---@return number
function Locales.SharedCount(base, overlay)
	local shared = 0

	for key in pairs(overlay or {}) do
		if base[key] ~= nil then
			shared = shared + 1
		end
	end

	return shared
end

---A key present on one side only counts as a difference.
---@param previous table<string, string>
---@param current table<string, string>
---@return boolean
function Locales.Differs(previous, current)
	for key, value in pairs(current) do
		if previous[key] ~= value then
			return true
		end
	end

	for key in pairs(previous) do
		if current[key] == nil then
			return true
		end
	end

	return false
end

---@param base table<string, string>
---@param overlay table<string, string>?
function Locales.Merge(base, overlay)
	for key, value in pairs(overlay or {}) do
		base[key] = value
	end
end

---Substitutions replace `%{name}` placeholders; an unknown key renders as itself.
---@param resourceName string
---@param key string
---@param substitutions table<string, any>?
---@return string
function Locales.Get(resourceName, key, substitutions)
	local value = Locales.strings[resourceName] and Locales.strings[resourceName][key]
	if type(value) ~= "string" then
		return key
	end

	if not substitutions then
		return value
	end

	return (value:gsub("%%{(.-)}", function(name)
		local substitution = substitutions[name]
		return substitution ~= nil and tostring(substitution) or ("%%{%s}"):format(name)
	end))
end

---Installs `Locale` on the bridge, so consuming resources call `Bridge.Locale('shop.tooFar')`.
---@param bridge BridgeLib.Bridge
---@param resourceName string
function Locales.Install(bridge, resourceName)
	bridge.exports.Locale = function(key, substitutions)
		return Locales.Get(resourceName, key, substitutions)
	end

	bridge:MarkImplemented({ "Locale" })
end

---Loads the shipped English, the cached language and the owner's overrides, in that precedence.
---@param resourceName string
---@param language string
---@return boolean shipsStrings Whether the resource ships an English file at all.
---@return number cached How many strings came out of the cached file, before any fetch.
---@return number overridden How many strings the owner's override file replaces.
function Locales.LoadFiles(resourceName, language)
	local source = Locales.ReadFile(resourceName, Locales.CachePath(Locales.SourceLanguage))
	if not source then
		return false, 0, 0
	end

	Locales.source[resourceName] = Locales.Copy(source)

	local cached = Locales.Count(source)

	if language ~= Locales.SourceLanguage then
		local overlay = Locales.ReadFile(resourceName, Locales.CachePath(language))
		cached = Locales.Count(overlay)

		Locales.Merge(source, overlay)
	end

	local overrides = Locales.ReadFile(resourceName, Locales.OverridePath(language)) or {}
	Locales.overrides[resourceName] = overrides
	Locales.Merge(source, overrides)

	Locales.strings[resourceName] = source
	return true, cached, Locales.Count(overrides)
end

---Prints the outcome of a fetch, failures included.
---@param resourceName string
---@param language string
---@param message string
---@param isError boolean?
function Locales.Report(resourceName, language, message, isError)
	print(("%s[%s] %s: %s^0"):format(isError and "^3" or "^2", resourceName, language, message))
end

---Fetches one language and caches it. A download matching what is on disk rewrites nothing.
---@param bridge BridgeLib.Bridge
---@param settings BridgeLib.Locales.Settings
---@param resourceName string
---@param language string
function Locales.Fetch(bridge, settings, resourceName, language)
	local url = ("%s/v1/scripts/%s/locales/%s?shape=nested"):format(
		settings.apiUrl or Locales.ApiUrl,
		resourceName:lower(),
		language
	)

	bridge:Verbose(("Requesting translations from %s"):format(url))

	PerformHttpRequest(url, function(status, body)
		if status ~= 200 or type(body) ~= "string" then
			Locales.Report(resourceName, language, ("no translations downloaded, the API returned status %s"):format(status), true)
			return
		end

		local success, response = pcall(json.decode, body)
		if not success or type(response) ~= "table" or type(response.strings) ~= "table" then
			Locales.Report(resourceName, language, "no translations downloaded, the API returned nothing usable", true)
			return
		end

		local overlay = Locales.Flatten(response.strings)
		local downloaded = Locales.Count(overlay)

		if downloaded == 0 then
			Locales.Report(resourceName, language, "the API holds no translations for this resource yet", true)
			return
		end

		local shipped = Locales.Count(Locales.source[resourceName])
		local translated = Locales.SharedCount(overlay, Locales.source[resourceName])

		local cached = Locales.ReadFile(resourceName, Locales.CachePath(language)) or {}

		if Locales.Differs(cached, overlay) then
			SaveResourceFile(resourceName, Locales.CachePath(language), json.encode(response.strings), -1)
		end

		local previous = Locales.strings[resourceName]

		local rebuilt = Locales.Copy(Locales.source[resourceName])
		Locales.Merge(rebuilt, overlay)
		Locales.Merge(rebuilt, Locales.overrides[resourceName])

		if not Locales.Differs(previous, rebuilt) then
			Locales.Report(
				resourceName,
				language,
				("downloaded %d strings, nothing the files already had has changed"):format(downloaded)
			)
			return
		end

		Locales.strings[resourceName] = rebuilt

		Locales.Report(
			resourceName,
			language,
			("downloaded %d strings, %d of %d keys translated, cached in locales/%s.json"):format(
				downloaded,
				translated,
				shipped,
				language
			)
		)

		local stillOverridden = Locales.SharedCount(overlay, Locales.overrides[resourceName])

		if stillOverridden > 0 then
			Locales.Report(
				resourceName,
				language,
				("%d of them stay replaced by locales/%s.local.json"):format(stillOverridden, language)
			)
		end

		TriggerClientEvent(Locales.DeliverEvent, -1, resourceName, Locales.strings[resourceName])
	end, "GET")
end

---Answers clients asking for this resource's strings.
---@param resourceName string
function Locales.Serve(resourceName)
	RegisterNetEvent(Locales.RequestEvent, function(requested)
		if requested ~= resourceName then
			return
		end

		local playerId = source
		local now = os.time()

		if Locales.lastRequest[playerId] and now - Locales.lastRequest[playerId] < Locales.RequestCooldown then
			return
		end
		Locales.lastRequest[playerId] = now

		TriggerClientEvent(Locales.DeliverEvent, playerId, resourceName, Locales.strings[resourceName])
	end)

	AddEventHandler("playerDropped", function()
		Locales.lastRequest[source] = nil
	end)
end

---Takes the strings the server settled on. Asked for unconditionally, English servers included.
---@param resourceName string
function Locales.Receive(resourceName)
	RegisterNetEvent(Locales.DeliverEvent, function(delivered, strings)
		if delivered ~= resourceName or type(strings) ~= "table" then
			return
		end

		Locales.strings[resourceName] = strings
	end)

	CreateThread(function()
		Wait(Locales.ReplicationDelay)

		TriggerServerEvent(Locales.RequestEvent, resourceName)
	end)
end

---Called by `BridgeLib.New` for every bridge; a repeat call for the same context is a no-op.
---@param bridge BridgeLib.Bridge
function Locales.Register(bridge)
	local resourceName = GetCurrentResourceName()
	local registration = ("%s:%s"):format(resourceName, bridge.context)

	if Locales.registered[registration] then
		return
	end
	Locales.registered[registration] = true

	---@type BridgeLib.Locales.Settings
	local settings = bridge.context == "server" and bridge:GetModuleConfig("locales") or {}
	local language = settings.language or GlobalState[Locales.LanguageKey] or Locales.SourceLanguage

	local shipsStrings, cached, overridden = Locales.LoadFiles(resourceName, language)

	if not shipsStrings then
		Locales.strings[resourceName] = {}
		Locales.overrides[resourceName] = {}
		Locales.source[resourceName] = {}
		Locales.Install(bridge, resourceName)
		return
	end

	Locales.Install(bridge, resourceName)

	if bridge.context == "client" then
		Locales.Receive(resourceName)
		return
	end

	if bridge.context ~= "server" then
		return
	end

	local replaced = Locales.SharedCount(Locales.source[resourceName], Locales.overrides[resourceName])

	if replaced > 0 then
		Locales.Report(
			resourceName,
			language,
			("%d strings replaced from locales/%s.local.json"):format(replaced, language)
		)
	end

	if overridden > replaced then
		Locales.Report(
			resourceName,
			language,
			("%d keys in locales/%s.local.json match no shipped string, so nothing renders them"):format(
				overridden - replaced,
				language
			),
			true
		)
	end

	GlobalState[Locales.LanguageKey] = language

	Locales.Serve(resourceName)

	if settings.enabled == false then
		Locales.Report(resourceName, language, ("using %d cached strings, the API is disabled"):format(cached), cached == 0)
		return
	end

	Locales.Report(
		resourceName,
		language,
		cached > 0 and ("using %d strings from file, checking the API for changes"):format(cached)
			or "nothing on file yet, asking the API"
	)

	CreateThread(function()
		Wait(settings.delay or Locales.Delay)

		Locales.Fetch(bridge, settings, resourceName, language)
	end)
end

return Locales
