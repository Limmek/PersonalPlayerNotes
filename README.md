[![CI](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/ci.yml/badge.svg)](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/ci.yml)
[![Interface versions](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/interface-version.yml/badge.svg)](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/interface-version.yml)
[![Release](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/release.yml/badge.svg)](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/release.yml)

# Personal Player Notes

Tag players with personal notes and color-coded reasons so you always remember who they are — shown directly in their tooltip and optionally announced with a sound the next time you run into them.

**Download**: [CurseForge](https://www.curseforge.com/wow/addons/personal-player-notes) · [GitHub Releases](https://github.com/Limmek/PersonalPlayerNotes/releases)

## Features

- **Notes** — write a free-text note on any player
- **Reasons** — define reusable categories (e.g. "Great healer", "Ninja looter") with their own color and alert sound
- **Tooltip integration** — note and reason are shown the moment you hover over a listed player
- **Alert sounds** — optionally play a sound when you first encounter a listed player in a session
- **Minimap button** — quick access to all settings and lists
- **Context menu** — right-click any player (unit frame, chat link, etc.) to add or edit a note instantly

## Supported WoW clients

<img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/Limmek/PersonalPlayerNotes/master/.github/badges/retail.json" alt="Retail">
<img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/Limmek/PersonalPlayerNotes/master/.github/badges/vanilla.json" alt="Classic Era">
<img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/Limmek/PersonalPlayerNotes/master/.github/badges/titan.json" alt="Wrath CN">
<img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/Limmek/PersonalPlayerNotes/master/.github/badges/tbc.json" alt="TBC Anniversary">
<img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/Limmek/PersonalPlayerNotes/master/.github/badges/mists.json" alt="Mists Classic">

| Client                                  | Status |
|------------------------------------------|--------|
| Retail                                   | ✅ Supported |
| Classic Era (incl. Hardcore, SoM, SoD)  | ✅ Supported |
| Wrath Classic (CN/Titan servers)         | ✅ Supported |
| Burning Crusade Classic (Anniversary)    | ✅ Supported |
| Mists of Pandaria Classic                | ✅ Supported |
| Cataclysm Classic                        | ❌ Retired by Blizzard — all realms moved to Mists of Pandaria Classic on 2025-07-01 |

## Installation

### Via addon manager (recommended)

Install through the [CurseForge App](https://www.curseforge.com/download/app) or [WowUp](https://wowup.io/) (or any other addon manager that supports CurseForge). Search for **Personal Player Notes** and click Install.

### Manual installation

1. Download the latest zip from [GitHub Releases](https://github.com/Limmek/PersonalPlayerNotes/releases) or [CurseForge](https://www.curseforge.com/wow/addons/personal-player-notes).
2. Extract the zip into your WoW `Interface/AddOns/` folder. The zip already contains the `PersonalPlayerNotes/` folder — after extraction it should look like:
   ```
   World of Warcraft/
   └── _retail_/          (or _classic_era_, _classic_, etc.)
       └── Interface/
           └── AddOns/
               └── PersonalPlayerNotes/
                   ├── PersonalPlayerNotes.toc
                   ├── PersonalPlayerNotes.lua
                   └── ...
   ```
3. Start or reload the game (`/reload`) and enable the addon on the character-select AddOns screen.

> **Migrating from the old Shitlist addon?** Keep Shitlist installed for one login after installing Personal Player Notes — it will offer to migrate your reasons and players automatically, after which Shitlist can safely be removed.

## Usage

| Command | Effect |
|---------|--------|
| `/ppn` | Open the Blizzard AddOns options page for this addon |
| `/ppno` or `/ppnoptions` | Open the general settings |
| `/ppnr` or `/ppnreasons` | Manage reasons (categories) |
| `/ppnp` or `/ppnplayers` | Manage listed players |
| `/ppnm` or `/ppnminimap` | Toggle the minimap button |
| `/ppndebug` | Toggle debug output |

The minimap button supports left-click, right-click, shift-click, and ctrl-click — hover it in-game for a full list of shortcuts.

## Data storage

All data is stored in the `PersonalPlayerNotesDB` SavedVariables file, which contains your reasons, player notes, and all settings. Nothing is sent externally.

---

Contributing? See [.github/CONTRIBUTING.md](.github/CONTRIBUTING.md).
