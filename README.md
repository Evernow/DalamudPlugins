# Evernow's Dalamud Plugins

Custom [Dalamud](https://github.com/goatcorp/Dalamud) plugin repository.

## Install

In game: **Dalamud Settings → Experimental → Custom Plugin Repositories**, add:

```
https://raw.githubusercontent.com/Evernow/DalamudPlugins/main/pluginmaster.json
```

Save, then find the plugins under `/xlplugins`.

## Plugins

| Plugin | Source | What it does |
|---|---|---|
| **Emptor** | [Evernow/Emptor](https://github.com/Evernow/Emptor) | Buys a shopping list off the market board (with a Dalamud IPC API). |

## How this repo updates

Each plugin lives in its own repository and publishes an `Emptor.zip` +
`Emptor.json` on its GitHub Releases. The [`sync`](.github/workflows/sync.yml)
workflow here reads each plugin's latest release manifest and refreshes
`pluginmaster.json` (version, API level, timestamp). Runs hourly and on demand.
