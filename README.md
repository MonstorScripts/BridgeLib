# BridgeLib

BridgeLib is a resource-agnostic bridge for FiveM Lua resources. Declare the modules your resource needs and it selects a supported provider that is running, exposing one framework-neutral API.

## Installation

### Standalone resource

Place BridgeLib in your resources directory and ensure it starts before its consumers. Consumers need `@ox_lib/init.lua` in `shared_scripts`.

```lua
local BridgeLib = require("@BridgeLib.init")
BridgeLib.SetRoot("@BridgeLib")
```

### Submodule

```bash
git submodule add <repo-url> BridgeLib
```

Include BridgeLib and ox_lib in the consumer's manifest:

```lua
shared_scripts({
    "@ox_lib/init.lua",
    "BridgeLib/**.lua",
    -- your files
})
```

If it lives somewhere other than `BridgeLib/`, pass that path to `SetRoot`.

## Usage

```lua
local BridgeLib = require("BridgeLib.init")

local exports = {}

local bridge = BridgeLib.New({
    context = "client",
    schema = exports,
    modules = { "framework", "inventory", "target" },
    optionalModules = { "fuel", "phone" },
})

bridge:On("playerLoaded", function() end)

CreateThread(function()
    bridge:LoadAll()
end)

return exports
```

`modules` require a running provider; `optionalModules` retain their safe fallback stubs when no provider is available. Call `LoadAll` after startup so provider resources can be detected.

## Catalog

| module | context | providers |
| --- | --- | --- |
| `framework` | client / server / shared | `qb-core`, `es_extended` |
| `inventory` | client / server | `qb-inventory`, `ox_inventory`, `codem-inventory`, `qs-inventory-pro`, `qs-inventory`, `origen_inventory`, `tgiann-inventory`, `jaksam_inventory`, `core_inventory`, `one_inventory`, and client-only `lj-inventory`, `ps-inventory` |
| `target` | client | `qb-target`, `ox_target`, `qtarget` |
| `zones` | client | `ox_lib`, `PolyZone` |
| `society` | server | `esx_addonaccount`, `qb-management`, `Renewed-Banking`, `qb-banking`, `okokBanking`, `snipe-banking`, `tgiann-bank`, `kartik-banking` |
| `multijob` | server | `monstor-multijob` |
| `bossmenu` | client / server | `monstor-bossmenu` |
| `fuel` | client | `rcore_fuel`, `LegacyFuel`, `cdn-fuel`, `okokGasStation`, `ox_fuel` |
| `vehiclekeys` | client | `qb-vehiclekeys`, `wasabi_carlock`, `qs-vehiclekeys`, `vehicles_keys` |
| `clothing` | client | `illenium-appearance`, `fivem-appearance`, `tgiann-clothing`, `rcore_clothing`, `qb-clothing`, `esx_skin` |
| `playerstatus` | client / server | `esx_status`, `qb-core` |
| `dispatch` | client | `cd_dispatch`, `linden_outlawalert`, `fd_dispatch`, `ps-dispatch`, `qs-dispatch`, `core_dispatch`, `origen_police`, `codem-dispatch`, `tk_dispatch`, `aty_dispatch`, `rcore_dispatch`, `Opto_dispatch` |
| `doorlock` | client / server | `ox_doorlock`, `qb-doorlock`, `nui-doorlock`, `cd_doorlock`, `doors_creator` |
| `phone` | client / server | `lb-phone`, `npwd`, `sql` |
| `email` | client / server | Client: `qb-phone`, `qs-smartphone-pro`, `qs-smartphone`, `gksphone` / `gks-phone`, `roadphone`, `npwd` / `npwd-phone`. Server: `lb-phone`, `high-phone`, `yseries`, `yflip-phone`, `okokPhone`, `npwd_qbx_mail`, `npwd_qb_mail` |
| `ui` | client | `lation_ui`, `ox_lib`, `cd_drawtextui`, `qb-core`, `esx_progressbar`, `jg-textui`, `esx_textui`, `brutal_textui`, `esx_notify`, `okokNotify`, `wasabi_notify`, `brutal_notify`, `mythic_notify` |
| `minigames` | client | `BridgeLib` |
| `logging` | server | `fmsdk`, `fm-logs`, `loki`, `BridgeLib` |

## Configuration

`config.lua` holds server-only configuration, including webhooks, logging, phone SQL access, update checks, and translations. Do not add it to your resource manifest: anything in `files` is sent to clients.

BridgeLib includes optional update checks and locale downloads through the Monstor Versions API. Both are enabled by default and can be configured or disabled in `config.lua`.

## Extending BridgeLib

Add a provider at `providers/<module>/<context>/<resource-name>.lua`, then list it in the matching descriptor under `modules/`. Provider order is priority order.

To add a module, create a descriptor under `modules/<name>/<context>.lua` with its schema, providers, and required functions. Consumers can also register project-specific descriptors:

```lua
BridgeLib.RegisterModule(require("myresource.bridge.modules.banking"))
bridge:Use("banking")
```

## API

- `BridgeLib.New(options)` creates a bridge.
- `bridge:LoadAll()` loads declared modules and verifies required functions.
- `bridge:Use(name)` / `bridge:UseOptional(name)` loads a module directly.
- `bridge:On(event, handler)` / `bridge:Emit(event, ...)` handles lifecycle events.
- `BridgeLib.SetRoot(path)` sets the library mount path.
- `BridgeLib.SetLogger(logger)` configures `{ debug, verbose, fatal }` logging.
- `BridgeLib.RegisterModule(module)` adds or replaces a module descriptor.

The framework module emits `playerLoaded`, `playerUnloaded`, `jobUpdated`, and `playerDataUpdated` with normalised payloads.
