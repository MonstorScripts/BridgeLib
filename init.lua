---@alias BridgeLib.Context "client"|"server"|"shared"

---Sink for the library's diagnostics. `fatal` is expected not to return.
---@class BridgeLib.Logger
---@field debug fun(message: string)
---@field verbose fun(message: string)
---@field fatal fun(message: string)

---A provider whose adapter file is not named after its resource, or which the library hosts itself.
---@class BridgeLib.Provider
---@field resource string? FiveM resource name, tested with `GetResourceState`. Omit for an adapter the library ships, which is available wherever the library is.
---@field adapter string? Adapter file name inside the module's provider path, defaulting to `resource`. Required when `resource` is omitted.
---@field module string? Require path of the adapter, overriding `adapter`.

---@alias BridgeLib.ProviderList (string|BridgeLib.Provider)[]

---One module's contract for one context: what it exports, who can supply it, and what a supplier
---must implement to count.
---@class BridgeLib.Module
---@field name string
---@field context BridgeLib.Context
---@field schema table<string, function> Every export the module defines, as callable stubs.
---@field providers BridgeLib.ProviderList Candidate resources, in preference order.
---@field required string[]? Schema keys a provider must implement, or loading fatals.
---@field providerPath string? Require prefix for adapters, defaulting to `<root>.providers.<name>.<context>.`.
---@field events string[]? Lifecycle events the module's providers may `bridge:Emit`. Documentation only.

---@class BridgeLib.Options
---@field context BridgeLib.Context
---@field schema table? Table that becomes `bridge.exports`; a fresh one is created when omitted.
---@field modules string[]? Modules to declare as required.
---@field optionalModules string[]? Modules to declare as optional.
---@field label string? Prefix for this bridge's log lines, defaulting to `context`.
---@field optional string[]? Schema keys exempted from `Verify`, for exports nothing has to implement.
---@field logger BridgeLib.Logger? Overrides the library wide logger for this bridge only.
---@field require (fun(module: string): any)? Module loader, defaulting to the ambient `require`.

---A module declared on a bridge but not necessarily loaded yet.
---@class BridgeLib.Declaration
---@field module BridgeLib.Module
---@field optional boolean Whether a missing provider is tolerated.
---@field done boolean Whether `LoadDeclared` has already run for it.

local BridgeLib = {}

BridgeLib._VERSION = "0.5.0"

local function noop() end

---@type BridgeLib.Logger
BridgeLib.Logger = {
	debug = function(message)
		print(("[BridgeLib] %s"):format(message))
	end,
	verbose = noop,
	fatal = function(message)
		error(("[BridgeLib] %s"):format(message), 0)
	end,
}

---@type string
BridgeLib.Root = "BridgeLib"

---Descriptors resolved so far, keyed by context then module name.
---@type table<string, table<string, BridgeLib.Module>>
BridgeLib.Modules = {}

---Settings shared by every bridge, loaded once from `<root>.config` on first use. Modules read
---their own section out of it, so one file configures the whole library.
---@type table?
BridgeLib.Config = nil

---Supplies configuration directly, ahead of the `config.lua` the library ships. Servers that keep
---their secrets outside the repository call this before building a bridge.
---@param config table
function BridgeLib.SetConfig(config)
	assert(type(config) == "table", "BridgeLib.SetConfig expects a config table")
	BridgeLib.Config = config
end

---Replaces the library wide default logger. Individual bridges may still override it.
---@param logger BridgeLib.Logger
function BridgeLib.SetLogger(logger)
	BridgeLib.Logger = logger
end

---Sets the require path the library is mounted at, when it is not `BridgeLib`.
---@param path string
function BridgeLib.SetRoot(path)
	BridgeLib.Root = path
end

---Registers a module descriptor, overriding or extending the shipped catalog.
---@param module BridgeLib.Module
function BridgeLib.RegisterModule(module)
	assert(type(module) == "table", "BridgeLib.RegisterModule expects a module table")
	assert(type(module.name) == "string", "a module requires a name")
	assert(type(module.context) == "string", "a module requires a context")

	BridgeLib.Modules[module.context] = BridgeLib.Modules[module.context] or {}
	BridgeLib.Modules[module.context][module.name] = module
end

---Returns true when the named resource is running.
---@param resourceName string
---@return boolean
function BridgeLib.HasResource(resourceName)
	local state = GetResourceState(resourceName)
	return state == "started" or state == "starting"
end

---Builds a schema stub that raises a fatal error when it is called without an implementation.
---@param name string
---@return fun(...): nil
function BridgeLib.Unimplemented(name)
	return function()
		BridgeLib.Logger.fatal(("Called '%s', which no loaded resource implements."):format(name))
	end
end

---@param provider string|BridgeLib.Provider
---@param pathPrefix string?
---@return string? resource, string module, string label
local function resolveProvider(provider, pathPrefix)
	if type(provider) == "string" then
		return provider, (pathPrefix or "") .. provider, provider
	end

	local name = provider.resource or provider.adapter
	assert(type(name) == "string", "a provider requires a resource or an adapter name")

	return provider.resource, provider.module or ((pathPrefix or "") .. (provider.adapter or name)), name
end

---@param providers BridgeLib.ProviderList
---@return string
local function describe(providers)
	local names = {}
	for index, provider in ipairs(providers) do
		local _, _, label = resolveProvider(provider)
		names[index] = label
	end
	return table.concat(names, ", ")
end

---One context's merged view of every module it declared.
---@class BridgeLib.Bridge
---@field exports table The flat table of functions callers use.
---@field context BridgeLib.Context
---@field label string
---@field logger BridgeLib.Logger?
---@field implemented table<string, boolean> Schema keys a provider supplied, or that `Verify` may skip.
---@field loaded table<string, string> Module name to the resource that satisfied it.
---@field declared BridgeLib.Declaration[]
---@field handlers table<string, function[]> Lifecycle handlers registered through `On`.
---@field require fun(module: string): any Loader used for adapter and module descriptor files.
local Bridge = {}
Bridge.__index = Bridge

---@return BridgeLib.Logger
function Bridge:GetLogger()
	return self.logger or BridgeLib.Logger
end

---The library's configuration, loaded from `<root>.config` the first time anything asks for it. A
---missing or malformed file resolves to an empty table, so every module falls back to its defaults
---rather than the library failing to load.
---
---`config.lua` is not shipped to clients, so this resolves to an empty table in a client context
---unless one was handed over with `SetConfig`. Nothing secret in it can leak that way, and no
---client module reads it.
---@return table
function Bridge:GetConfig()
	if BridgeLib.Config then
		return BridgeLib.Config
	end

	local path = ("%s.config"):format(BridgeLib.Root)
	local success, config = pcall(self.require, path)

	if not success or type(config) ~= "table" then
		self:Debug(("No config loaded from '%s', using defaults"):format(path))
		config = {}
	end

	BridgeLib.Config = config
	return config
end

---One module's section of the configuration, always a table.
---@param name string
---@return table
function Bridge:GetModuleConfig(name)
	local section = self:GetConfig()[name]
	return type(section) == "table" and section or {}
end

---@param message string
function Bridge:Fatal(message)
	self:GetLogger().fatal(("[%s] %s"):format(self.label, message))
end

---@param message string
function Bridge:Debug(message)
	self:GetLogger().debug(("[%s] %s"):format(self.label, message))
end

---@param message string
function Bridge:Verbose(message)
	self:GetLogger().verbose(("[%s] %s"):format(self.label, message))
end

---Registers a handler for a lifecycle event emitted by a provider.
---@param event string
---@param handler function
function Bridge:On(event, handler)
	self.handlers[event] = self.handlers[event] or {}
	local handlers = self.handlers[event]
	handlers[#handlers + 1] = handler
end

---Emits a lifecycle event to every registered handler.
---@param event string
---@param ... any
function Bridge:Emit(event, ...)
	local handlers = self.handlers[event]
	if not handlers then
		return
	end

	for _, handler in ipairs(handlers) do
		handler(...)
	end
end

---Marks schema keys as satisfied so `Verify` will not report them as missing.
---@param keys string[]
function Bridge:MarkImplemented(keys)
	for _, key in ipairs(keys) do
		self.implemented[key] = true
	end
end

---Copies schema stubs onto the bridge without claiming they are implemented. Keys already present
---are left alone, so the first module to declare an export wins.
---@param schema table<string, function>
function Bridge:Install(schema)
	for key, value in pairs(schema) do
		if self.exports[key] == nil then
			self.exports[key] = value
		end
	end
end

---Requires one adapter file, calling it with the bridge when it returns a builder function.
---Returns nil rather than raising when the adapter fails to load or yields the wrong shape.
---@param provider string
---@param module string
---@return table? implementation
function Bridge:LoadModule(provider, module)
	local success, result = pcall(self.require, module)
	if not success then
		self:Debug(("Error loading module '%s' for provider '%s': %s"):format(module, provider, result))
		return nil
	end

	if type(result) == "function" then
		success, result = pcall(result, self)
		if not success then
			self:Debug(("Error building module '%s' for provider '%s': %s"):format(module, provider, result))
			return nil
		end
	end

	if type(result) ~= "table" then
		self:Debug(("Module '%s' for provider '%s' did not return a table"):format(module, provider))
		return nil
	end

	return result
end

---@param resource string
---@param implementation table<string, function>
function Bridge:Apply(resource, implementation)
	for key, value in pairs(implementation) do
		self:Verbose(("Exporting '%s' from resource '%s'"):format(key, resource))
		self.exports[key] = value
		self.implemented[key] = true
	end
end

---Loads the adapter for the first available provider. A provider whose resource is running but whose
---adapter fails to load resolves to nothing rather than falling through to the next candidate. A
---provider naming no resource is one the library ships itself, so it is always available.
---@param providers BridgeLib.ProviderList
---@param pathPrefix string?
---@return string? resource, table? implementation
function Bridge:Resolve(providers, pathPrefix)
	for _, provider in ipairs(providers) do
		local resource, module, label = resolveProvider(provider, pathPrefix)
		if not resource or BridgeLib.HasResource(resource) then
			local implementation = self:LoadModule(label, module)
			if implementation then
				return label, implementation
			end
			return nil, nil
		end
	end
	return nil, nil
end

---Loads the first running provider onto the bridge, raising a fatal error when none is available.
---@param providers BridgeLib.ProviderList
---@param pathPrefix string?
---@return string? resource
function Bridge:Load(providers, pathPrefix)
	local resource, implementation = self:Resolve(providers, pathPrefix)
	if not resource or not implementation then
		self:Fatal(("Failed to load any supported resource, supported resources are '%s'"):format(describe(providers)))
		return nil
	end

	self:Debug(("Loaded resource '%s'"):format(resource))
	self:Apply(resource, implementation)
	return resource
end

---Loads the first running provider onto the bridge, leaving the schema stubs in place when none is available.
---@param providers BridgeLib.ProviderList
---@param pathPrefix string?
---@return string? resource
function Bridge:LoadOptional(providers, pathPrefix)
	local resource, implementation = self:Resolve(providers, pathPrefix)
	if not resource or not implementation then
		self:Debug(("No optional resource found (supported: '%s'), using defaults"):format(describe(providers)))
		return nil
	end

	self:Debug(("Loaded optional resource '%s'"):format(resource))
	self:Apply(resource, implementation)
	return resource
end

---Returns a registered descriptor, otherwise requires it from the catalog and registers it.
---@param name string
---@return BridgeLib.Module
function Bridge:GetModule(name)
	local registered = BridgeLib.Modules[self.context] and BridgeLib.Modules[self.context][name]
	if registered then
		return registered
	end

	local path = ("%s.modules.%s.%s"):format(BridgeLib.Root, name, self.context)
	local success, module = pcall(self.require, path)
	if not success or type(module) ~= "table" then
		self:Fatal(("No '%s' module exists for context '%s' (looked for '%s')"):format(name, self.context, path))
	end

	BridgeLib.RegisterModule(module)
	return module
end

---@param module BridgeLib.Module
---@return string
function Bridge:GetProviderPath(module)
	return module.providerPath or ("%s.providers.%s.%s."):format(BridgeLib.Root, module.name, module.context)
end

---Installs a catalog module's schema without loading a provider for it yet. Keys outside `required`
---count as implemented from the start, so `Verify` only insists on the mandatory ones.
---@param name string
---@param isOptional boolean
---@return BridgeLib.Declaration
function Bridge:Declare(name, isOptional)
	local module = self:GetModule(name)
	self:Install(module.schema)

	local isRequired = {}
	if not isOptional then
		for _, key in ipairs(module.required or {}) do
			isRequired[key] = true
		end
	end

	for key in pairs(module.schema) do
		if not isRequired[key] then
			self.implemented[key] = true
		end
	end

	---@type BridgeLib.Declaration
	local declaration = {
		module = module,
		optional = isOptional,
		done = false,
	}

	self.declared[#self.declared + 1] = declaration
	return declaration
end

---@param declaration BridgeLib.Declaration
---@return string? resource
function Bridge:LoadDeclared(declaration)
	local module = declaration.module
	local path = self:GetProviderPath(module)
	declaration.done = true

	if declaration.optional then
		local resource = self:LoadOptional(module.providers, path)
		self.loaded[module.name] = resource
		return resource
	end

	local resource = self:Load(module.providers, path)
	if not resource then
		return nil
	end

	for _, key in ipairs(module.required or {}) do
		if not self.implemented[key] then
			self:Fatal(("Resource '%s' does not implement '%s' of the '%s' module"):format(resource, key, module.name))
		end
	end

	self.loaded[module.name] = resource
	return resource
end

---Loads a catalog module, raising a fatal error when none of its providers is running.
---@param name string
---@return string? resource
function Bridge:Use(name)
	return self:LoadDeclared(self:Declare(name, false))
end

---Loads a catalog module, keeping its fallback stubs when none of its providers is running.
---@param name string
---@return string? resource
function Bridge:UseOptional(name)
	return self:LoadDeclared(self:Declare(name, true))
end

---Loads every module declared through `New`, then verifies the bridge.
function Bridge:LoadAll()
	for _, declaration in ipairs(self.declared) do
		if not declaration.done then
			self:LoadDeclared(declaration)
		end
	end

	self:Verify()
end

---Raises a fatal error for every schema function that nothing implemented.
function Bridge:Verify()
	for key, value in pairs(self.exports) do
		if type(value) == "function" and not self.implemented[key] then
			self:Fatal(("Export '%s' was not set by any resource, but is defined in the schema."):format(key))
		end
	end
end

---Creates a bridge for one context. `options.schema`, when given, becomes `bridge.exports`.
---@param options BridgeLib.Options
---@return BridgeLib.Bridge
function BridgeLib.New(options)
	assert(type(options) == "table", "BridgeLib.New expects an options table")
	assert(type(options.context) == "string", "BridgeLib.New expects a context")

	local bridge = setmetatable({
		exports = options.schema or {},
		context = options.context,
		label = options.label or options.context,
		logger = options.logger,
		implemented = {},
		loaded = {},
		declared = {},
		handlers = {},
		require = options.require or require,
	}, Bridge)

	if options.optional then
		bridge:MarkImplemented(options.optional)
	end

	for _, name in ipairs(options.modules or {}) do
		bridge:Declare(name, false)
	end

	for _, name in ipairs(options.optionalModules or {}) do
		bridge:Declare(name, true)
	end

	return bridge
end

return BridgeLib
