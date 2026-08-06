---Translations, pulled from the monstor-versions API and cached in the resource.
---
---A resource ships `locales/en.json` and that file is the source of truth: it is always present,
---so a server with no internet, no cache and no configured language still has every string. Any
---other language is an overlay fetched from the API and written to `locales/<language>.json`, then
---merged over English at load. A key the overlay is missing falls back to the English one rather
---than to nothing.
---
---Files are i18next shaped - nested objects, keys as dot paths once flattened - which is the shape
---the API serves and the shape `ox_lib` reads, so the cache file is a normal locale file that can
---also be edited by hand.
---
---The server owns the fetch. A file written at runtime is not in the resource's manifest for this
---session, so clients cannot download it until the next restart; instead the server hands its
---merged strings to each client that asks, and pushes them again when a fetch changes them. Clients
---render English until that lands, which is the same second the bridge comes up.

---@class BridgeLib.Locales.Settings
---@field enabled boolean? Set to false to never contact the API, using only the shipped and cached files.
---@field language string? Language to render in, defaulting to the shipped English.
---@field apiUrl string? Overrides the hosted API.
---@field delay number? Milliseconds to wait after startup before fetching.

local Locales = {}

Locales.ApiUrl = "https://versions.monstorscripts.com"

Locales.Delay = 5000

---The language every resource ships, and the fallback for a key an overlay does not translate.
Locales.SourceLanguage = "en"

---Net event a client raises to ask for the strings the server ended up with, since it cannot read a
---file written after the resource started. Carries the resource name: event names are global to the
---server, so every resource's handler sees every request and answers only for its own.
Locales.RequestEvent = "BridgeLib:locales:request"

---Net event carrying one resource's strings back to a client.
Locales.DeliverEvent = "BridgeLib:locales:deliver"

---GlobalState key naming the language the server renders in. `config.lua` is never shipped to
---clients, so a client cannot read the setting itself and learns it from here instead. A server left
---on the shipped English never writes it, and its clients never ask for an overlay.
Locales.LanguageKey = "bridgeLibLocalesLanguage"

---Seconds a client must wait between requests, so the event cannot be used to make the server
---serialize a string table on a loop.
Locales.RequestCooldown = 5

---Milliseconds a client waits before reading the language, since a bridge built while the player is
---still connecting can run before the server's `GlobalState` has replicated.
Locales.ReplicationDelay = 2000

---Flat strings per resource, keyed by the runtime's own resource name. One Lua runtime is one
---resource, so this only ever holds one entry - it is keyed anyway so a mismatched delivery is
---dropped rather than overwriting the wrong table.
---@type table<string, table<string, string>>
Locales.strings = {}

---Resources already registered from this Lua runtime, so a resource building both a client and a
---server bridge only sets itself up once per context.
---@type table<string, boolean>
Locales.registered = {}

---Last request time per player, for `RequestCooldown`.
---@type table<number, number>
Locales.lastRequest = {}

---Nested locale table to flat dot paths. A value that is neither a string nor a table is dropped:
---the API only ever stores strings, so anything else is a hand-edited file gone wrong.
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

---Reads one locale file out of the resource and flattens it. A missing or malformed file resolves
---to nothing, so a resource that ships no translations simply has none.
---@param resourceName string
---@param language string
---@return table<string, string>?
function Locales.ReadFile(resourceName, language)
	local contents = LoadResourceFile(resourceName, ("locales/%s.json"):format(language))
	if not contents then
		return nil
	end

	local success, decoded = pcall(json.decode, contents)
	if not success or type(decoded) ~= "table" then
		return nil
	end

	return Locales.Flatten(decoded)
end

---Copies an overlay over a base, keeping the base's value for any key the overlay leaves out.
---@param base table<string, string>
---@param overlay table<string, string>?
function Locales.Merge(base, overlay)
	for key, value in pairs(overlay or {}) do
		base[key] = value
	end
end

---Renders one key. Substitutions replace `%{name}` placeholders. An unknown key renders as itself
---so a missing translation shows up as the key rather than as an empty notification.
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

---Loads the shipped English file and, when another language is configured, whatever of it has
---already been cached.
---@param resourceName string
---@param language string
---@return boolean shipsStrings Whether the resource ships an English file at all.
---@return number cached How many strings came out of the cached file, before any fetch.
function Locales.LoadFiles(resourceName, language)
	local source = Locales.ReadFile(resourceName, Locales.SourceLanguage)
	if not source then
		return false, 0
	end

	local cached = 0

	if language ~= Locales.SourceLanguage then
		local overlay = Locales.ReadFile(resourceName, language)

		for _ in pairs(overlay or {}) do
			cached = cached + 1
		end

		Locales.Merge(source, overlay)
	end

	Locales.strings[resourceName] = source
	return true, cached
end

---Prints the outcome of a fetch. A server that asked for a language wants to know whether it
---arrived, so unlike the update check this reports its failures too: silence would be
---indistinguishable from a resource quietly running in English.
---@param resourceName string
---@param language string
---@param message string
---@param isError boolean?
function Locales.Report(resourceName, language, message, isError)
	print(("%s[%s] %s: %s^0"):format(isError and "^3" or "^2", resourceName, language, message))
end

---Fetches one language from the API, caches it for the next start and merges it in for this one.
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
		local downloaded = 0
		for _ in pairs(overlay) do
			downloaded = downloaded + 1
		end

		if downloaded == 0 then
			Locales.Report(resourceName, language, "the API holds no translations for this resource yet", true)
			return
		end

		local shipped = 0
		local translated = 0
		for key in pairs(Locales.strings[resourceName]) do
			shipped = shipped + 1
			if overlay[key] then
				translated = translated + 1
			end
		end

		SaveResourceFile(resourceName, ("locales/%s.json"):format(language), json.encode(response.strings), -1)

		Locales.Merge(Locales.strings[resourceName], overlay)

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

		if translated < shipped then
			print(("^7  %d keys have no '%s' translation yet and stay in English.^0"):format(shipped - translated, language))
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

---Takes the strings the server settled on, whether they came from a cache this client never
---downloaded or from a fetch that landed after it connected. Asks only once the server has said it
---renders in something other than the shipped English, so a server on English is never asked at all.
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

		local language = GlobalState[Locales.LanguageKey]
		if not language or language == Locales.SourceLanguage then
			return
		end

		TriggerServerEvent(Locales.RequestEvent, resourceName)
	end)
end

---Sets the current resource up for translation. Called by `BridgeLib.New` for every bridge; calling
---it again for the same resource and context is a no-op.
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

	local shipsStrings, cached = Locales.LoadFiles(resourceName, language)

	if not shipsStrings then
		Locales.strings[resourceName] = {}
		Locales.Install(bridge, resourceName)
		return
	end

	Locales.Install(bridge, resourceName)

	if bridge.context == "client" then
		Locales.Receive(resourceName)
		return
	end

	if bridge.context ~= "server" or language == Locales.SourceLanguage then
		return
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
		cached > 0 and ("using %d cached strings, checking the API for changes"):format(cached)
			or "nothing cached yet, asking the API"
	)

	CreateThread(function()
		Wait(settings.delay or Locales.Delay)

		Locales.Fetch(bridge, settings, resourceName, language)
	end)
end

return Locales
