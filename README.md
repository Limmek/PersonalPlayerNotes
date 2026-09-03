[![CI](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/ci.yml/badge.svg)](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/ci.yml)
[![Interface versions](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/interface-version.yml/badge.svg)](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/interface-version.yml)
[![Release](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/release.yml/badge.svg)](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

# Personal Player Notes

**Remember who they are.**

Keep private reminders about players you meet. Add an optional note or color-coded reason for your own reference, then see it in their tooltip the next time you meet. Your information remains local to your computer and is never shared.

**Download**: [CurseForge](https://www.curseforge.com/wow/addons/personal-player-notes) · [GitHub Releases](https://github.com/Limmek/PersonalPlayerNotes/releases)

## Features

- **Remember players** — save a personal note, choose a reason, or use both; each is optional.
- **See it at a glance** — your notes and color-coded reasons appear when you hover over a player.
- **Organize your list** — create your own reasons, such as "Met in a dungeon", "Helpful player", "Crafter", or "Alchemy".
- **Know when they are nearby** — play an alert sound when you encounter someone on your list.
- **Choose how alerts repeat** — hear an alert once per session, or let it repeat after a delay.
- **Make alerts recognisable** — choose different sounds for your whole list, a reason, or an individual player; you can also add your own sound files.
- **Add players quickly** — right-click players from unit frames, chat links, and other supported places to add or edit them.
- **Easy access** — use the minimap button or slash commands to open your settings, reasons, and player list.
- **Use separate lists if you want** — keep different lists for different characters, or share one across them.
- **Keep your data private** — your notes and settings stay on your computer; nothing is sent anywhere.

## Supported WoW clients

| Client | Version |
|--------|---------|
| Retail | <img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/Limmek/PersonalPlayerNotes/master/.github/badges/retail.json" alt="Retail"> |
| Classic Era (incl. Hardcore, SoM, SoD) | <img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/Limmek/PersonalPlayerNotes/master/.github/badges/vanilla.json" alt="Classic Era"> |
| Wrath Classic (CN/Titan servers) | <img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/Limmek/PersonalPlayerNotes/master/.github/badges/titan.json" alt="Wrath CN"> |
| Burning Crusade Classic (Anniversary) | <img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/Limmek/PersonalPlayerNotes/master/.github/badges/tbc.json" alt="TBC Anniversary"> |
| Mists of Pandaria Classic | <img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/Limmek/PersonalPlayerNotes/master/.github/badges/mists.json" alt="Mists Classic"> |
| Cataclysm Classic | Retired by Blizzard — all realms moved to Mists of Pandaria Classic on 2025-07-01 |

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

## Commands

| Command | Effect |
|---------|--------|
| `/ppn` | Open the Blizzard AddOns options page for this addon |
| `/ppno` or `/ppnoptions` | Open the general settings |
| `/ppnr` or `/ppnreasons` | Manage reasons (categories) |
| `/ppnp` or `/ppnplayers` | Manage listed players |
| `/ppnm` or `/ppnminimap` | Toggle the minimap button |
| `/ppndebug` | Toggle debug output |

## Minimap shortcuts

The minimap button also responds directly to clicks (hover it in-game for the same list):

| Click | Effect |
|-------|--------|
| Left-click | Open the general settings |
| Right-click | Open the Blizzard AddOns options page |
| Shift + Left-click | Manage reasons (categories) |
| Ctrl + Left-click | Manage listed players |

## Alert sounds

Personal Player Notes can play a sound whenever you encounter a listed player. Alerts can either fire once per player for the rest of the session, or repeat after a configurable cooldown (in seconds), and the sound itself resolves in priority order:

```
Player's own sound override
        ↓ (falls back to)
Player's reason's sound override
        ↓ (falls back to)
Global alert sound
```

Any of the three levels can use one of the built-in sounds, or your own custom `.mp3`/`.ogg` file dropped into this addon's `Sounds/` folder.

## Reasons

Reasons are reusable categories (e.g. "Met in a dungeon", "Helpful player", "Crafter", or "Alchemy") that make your private reminders easier to tell apart at a glance. Each reason has its own:

- Name and tooltip color
- Alert on/off toggle
- Alert sound override

Listed players can also override the sound of their reason (or the global default) individually.

A reason is entirely optional — a listed player with no reason assigned just shows their note, with no color or alert sound override.

## Profiles

Settings, reasons, and listed players are all stored per-profile via Ace3's standard profile system — use a separate profile per character, or share one profile across every character on your account. Profiles can be copied, reset, or deleted from the general settings.

## Data storage

All data is stored locally in the `PersonalPlayerNotesDB` SavedVariables file, which contains your reasons, player notes, and settings. The addon has no sharing, publishing, or communication feature, and nothing is sent externally.

## License

[MIT](LICENSE)

---

Contributing? See [.github/CONTRIBUTING.md](.github/CONTRIBUTING.md).

<p align="center"><strong>Personal Player Notes</strong> — Remember who they are.</p>
