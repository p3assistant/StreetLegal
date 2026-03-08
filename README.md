# Street Legal

Street Legal is an original Roblox open-world dirt bike stunt MVP built for a Rojo + Roblox Studio workflow.

## Core Features

- Baltimore-inspired open world with distinct districts, shoreline, industrial blocks, alleys, parks, and off-road trails
- Spawnable dirt bikes with free starters and paid progression bikes
- Server-authoritative ownership, currency, and wanted state
- Police patrol + pursuit AI using `PathfindingService`
- Functional garage/shop UI and HUD
- Runtime world generation using primitives so the MVP works immediately in Studio

## Project Structure

```text
StreetLegal/
├── default.project.json
├── README.md
├── DELIVERABLE.md
├── build/
└── src/
    ├── ReplicatedStorage/
    ├── ServerScriptService/
    ├── StarterGui/
    ├── StarterPlayer/
    └── Workspace/
```

## Requirements

- Rojo 7+
- Roblox Studio
- Rojo Studio plugin (recommended for live sync)

## Studio Workflow

### Option A: Live sync with Rojo serve

```bash
cd /Users/assistant/.openclaw/workspace/projects/StreetLegal
rojo serve
```

Then in Roblox Studio:
1. Install/open the Rojo plugin.
2. Connect the plugin to the local Rojo server.
3. Open or create a place.
4. Sync the project tree.
5. Press Play to test.

### Option B: Build a place file

```bash
cd /Users/assistant/.openclaw/workspace/projects/StreetLegal
mkdir -p build
rojo build -o build/StreetLegal.rbxlx
```

Open `build/StreetLegal.rbxlx` in Roblox Studio.

## Testing Notes

- The world is generated at runtime by `Workspace/Map/CityBuilder.server.lua`.
- Garage/shop UI opens with `M`.
- Spawn/equip bikes from the garage.
- HUD shows speed, heat, district, combo, and prompts.
- Police will patrol automatically after the world is ready.
- In Studio, DataStore calls can fail if the place is unpublished or API services are disabled; the game falls back to session-only defaults.

## Tuning

Main tuning files:
- `src/ReplicatedStorage/Modules/Config.lua`
- `src/ReplicatedStorage/Modules/BikeDefinitions.lua`
- `src/ReplicatedStorage/Modules/WantedConfig.lua`

Bike feel defaults live in `Config.lua` under `Bike` and `ArcadeController`.

## Monetization Philosophy

This MVP uses a mix of free bikes and progression purchases. Premium hooks are present but kept ethical; the game is fully playable without spending Robux.
