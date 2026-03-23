# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ElvUI-Legion is a World of Warcraft UI replacement addon targeting the Legion 7.3.5 client (Interface: 70300). It is written entirely in Lua with XML for load ordering. There is no build system — the WoW client interprets Lua directly.

## Installation / Deployment

Copy the `ElvUI/` and `ElvUI_Config/` directories into:
```
World of Warcraft/_retail_/Interface/AddOns/
```

No compilation or build step is required.

## Development

There are no automated tests or lint tools. Development is done by:
- Editing Lua/XML files directly
- Loading the addon in the WoW 7.3.5 client
- Using in-game developer commands (`/reload`, `/console scriptErrors 1`)
- Using the `developer/` folder utilities for frame/table inspection

## Architecture

### The 5-Module Engine Pattern

Every file accesses the core engine via:
```lua
local E, L, V, P, G = unpack(select(2, ...))
```
- `E` — Main addon object (AceAddon), holds utilities and sub-modules
- `L` — Localization strings (AceLocale-3.0)
- `V` — Private/character-specific DB defaults (`ElvUI/Settings/Private.lua`)
- `P` — Profile defaults (`ElvUI/Settings/Profile.lua`)
- `G` — Global defaults (`ElvUI/Settings/Global.lua`)

This engine is assembled in `ElvUI/init.lua` and passed via the addon vararg.

### Module Registration

Feature modules use the Ace3 module pattern:
```lua
local MyModule = E:NewModule('MyModule', 'AceHook-3.0', 'AceEvent-3.0')
```
Modules initialize via `MyModule:Initialize()` called from `core.lua` during `PLAYER_LOGIN`.

### Database System

Three SavedVariables:
- `ElvDB` — Profile database (per-character, shareable profiles)
- `ElvPrivateDB` — Character-specific internals (not sharable)
- `ElvCharacterDB` — Legacy character data

Profile key format: `"character-name - realm-name"`

### Load Order

XML files control load order within each directory:
- `ElvUI/Libraries/Load_Libraries.xml` — third-party libs loaded first
- `ElvUI/locales/load_locales.xml` — then locales
- `ElvUI/Settings/Load_Config.xml` — then defaults
- `ElvUI/core/load_core.xml` — then core engine
- `ElvUI/Modules/load_modules.xml` — then feature modules

`ElvUI_Config/` is marked `LoadOnDemand: 1` in its TOC and only loads when the config UI is opened.

### Key Libraries

- **oUF** — Unit frame engine; all raid/party frames are oUF-based
- **LibSharedMedia-3.0** — Centralized font/texture/sound registry
- **LibActionButton-1.0** — Action button framework
- **Ace3 suite** — AceAddon, AceEvent, AceDB, AceHook, AceConfig, AceLocale, AceTimer, AceComm, AceSerializer

### Configuration UI

`ElvUI_Config/` is a separate companion addon. Each module has a corresponding config file (e.g., `ElvUI_Config/unitframes.lua` at 230KB is the largest). Config options use AceConfig-3.0 option tables registered via `E.Options`.

### Combat Lockdown

WoW restricts certain API calls during combat. The addon gates config UI access and frame moves behind combat state checks. Use `InCombatLockdown()` checks before touching protected frames.

### Localization

Ten languages supported in `ElvUI/locales/`. Always use `L["string key"]` for user-facing strings rather than hardcoded English.
