---@class BridgeLib.Logger
---@field debug fun(message: string)
---@field verbose fun(message: string)
---@field fatal fun(message: string)

---@class BridgeLib.Provider
---@field resource string
---@field module string?

---@alias BridgeLib.ProviderList (string|BridgeLib.Provider)[]

---@class BridgeLib.Module
---@field name string
---@field context string
---@field schema table
---@field providers BridgeLib.ProviderList
---@field required string[]?
---@field providerPath string?
---@field events string[]?

---@class BridgeLib.Options
---@field context string
---@field schema table?
---@field modules string[]?
---@field optionalModules string[]?
---@field label string?
---@field optional string[]?
---@field logger BridgeLib.Logger?
---@field require fun(module: string): any

local BridgeLib = {}

BridgeLib._VERSION = "0.2.0"

local function noop() end

---@type BridgeLib.Logger
BridgeLib.Logger = {
	debug = function(message)
		print(("[bridgelib] %s"):format(message))
	end,
	verbose = noop,
	fatal = function(message)
		error(("[bridgelib] %s"):format(message), 0)
	end,
}

BridgeLib.Root = "bridgelib"

BridgeLib.Modules = {}

---Replaces the library wide default logger. Individual bridges may still override it.
---@param logger BridgeLib.Logger
function BridgeLib.SetLogger(logger)
	BridgeLib.Logger = logger
end

---Sets the require path the library is mounted at, when it is not `bridgelib`.
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
---@return string resource, string module
local function resolveProvider(provider, pathPrefix)
	if type(provider) == "string" then
		return provider, (pathPrefix or "") .. provider
	end
	return provider.resource, provider.module or ((pathPrefix or "") .. provider.resource)
end

---@param providers BridgeLib.ProviderList
---@return string
local function describe(providers)
	local names = {}
	for index, provider in ipairs(providers) do
		names[index] = type(provider) == "string" and provider or provider.resource
	end
	return table.concat(names, ", ")
end

---@class BridgeLib.Bridge
---@field exports table
---@field context string
---@field label string
---@field logger BridgeLib.Logger?
---@field implemented table<string, boolean>
---@field loaded table<string, string>
---@field declared BridgeLib.Declaration[]
---@field handlers table<string, function[]>
local Bridge = {}
Bridge.__index = Bridge

---@return BridgeLib.Logger
function Bridge:GetLogger()
	return self.logger or BridgeLib.Logger
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

---Copies schema stubs onto the bridge without claiming they are implemented.
---@param schema table
function Bridge:Install(schema)
	for key, value in pairs(schema) do
		if self.exports[key] == nil then
			self.exports[key] = value
		end
	end
end

---@param resource string
---@param module string
---@return table? implementation
function Bridge:LoadModule(resource, module)
	local success, result = pcall(self.require, module)
	if not success then
		self:Debug(("Error loading module '%s' for resource '%s': %s"):format(module, resource, result))
		return nil
	end

	if type(result) == "function" then
		success, result = pcall(result, self)
		if not success then
			self:Debug(("Error building module '%s' for resource '%s': %s"):format(module, resource, result))
			return nil
		end
	end

	if type(result) ~= "table" then
		self:Debug(("Module '%s' for resource '%s' did not return a table"):format(module, resource))
		return nil
	end

	return result
end

---@param resource string
---@param implementation table
function Bridge:Apply(resource, implementation)
	for key, value in pairs(implementation) do
		self:Verbose(("Exporting '%s' from resource '%s'"):format(key, resource))
		self.exports[key] = value
		self.implemented[key] = true
	end
end

---@param providers BridgeLib.ProviderList
---@param pathPrefix string?
---@return string? resource, table? implementation
function Bridge:Resolve(providers, pathPrefix)
	for _, provider in ipairs(providers) do
		local resource, module = resolveProvider(provider, pathPrefix)
		if BridgeLib.HasResource(resource) then
			local implementation = self:LoadModule(resource, module)
			if implementation then
				return resource, implementation
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

---Installs a catalog module's schema without loading a provider for it yet.
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

	---@class BridgeLib.Declaration
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
