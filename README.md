[![CI](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/ci.yml/badge.svg)](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/ci.yml)
[![Interface versions](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/interface-version.yml/badge.svg)](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/interface-version.yml)
[![Release](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/release.yml/badge.svg)](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/release.yml)

# Personal Player Notes *(former #Shitlist)*

Set personal notes and pre-defined descriptions ("reasons") on players to remind yourself of who they are in the future. The note and its reason are shown directly in the player's tooltip and, optionally, as an alert sound the next time you encounter them. Both reasons and individual player notes support their own text color and their own alert sound.

Notes and reasons can be managed:
- By right-clicking a player's unit frame or name in chat
- From the in-game GUI (`/ppn`, `/ppnr`, `/ppnp`, see [Usage](#usage))
- Via the Blizzard AddOns options panel
- From the minimap button (left/right/shift/ctrl-click for different shortcuts, see its tooltip)

**Download**: latest release on [GitHub](https://github.com/Limmek/PersonalPlayerNotes/releases) or [CurseForge](https://www.curseforge.com/wow/addons/personal-player-notes).

## Supported WoW clients

| Client                                 | Status      |
|-----------------------------------------|-------------|
| Retail                                  | Supported   |
| Classic Era (incl. Hardcore, SoM, SoD)  | Supported   |
| Wrath Classic                           | Supported   |
| Mists of Pandaria Classic               | Supported   |
| Cataclysm Classic                       | Retired by Blizzard (all realms moved to Mists of Pandaria Classic on 2025-07-01); no longer supported |
| Burning Crusade Classic (Anniversary)   | Not currently supported                    |

## Installation

1. Download the latest release from [CurseForge](https://www.curseforge.com/wow/addons/personal-player-notes) or [GitHub Releases](https://github.com/Limmek/PersonalPlayerNotes/releases) (or install it through your addon manager of choice).
2. Extract it into your WoW `Interface/AddOns` folder so that `PersonalPlayerNotes.toc` sits directly inside `Interface/AddOns/PersonalPlayerNotes/`.
3. Enable the addon on the character-select AddOns list.

If you previously used the old `Shitlist` addon, keep it installed for one login after installing Personal Player Notes — it will offer to migrate your reasons and listed players automatically, after which it can safely be removed.

## Usage

| Command                     | Effect                                          |
|-------------------------------|--------------------------------------------------|
| `/ppn`                       | Open the Blizzard options to this addon's page   |
| `/ppno` or `/ppnoptions`     | Open the general settings                        |
| `/ppnr` or `/ppnreasons`     | Manage reasons (categories)                      |
| `/ppnp` or `/ppnplayers`     | Manage listed players                            |
| `/ppnm` or `/ppnminimap`     | Toggle the minimap button                        |
| `/ppndebug`                  | Toggle debug output                              |

Right-clicking a player (unit frame, chat, etc.) adds a "Personal Player Notes" entry to their context menu for quickly adding/editing a note. Hovering a listed player's tooltip shows their reason and note in the configured colors, and can optionally play an alert sound.

## SavedVariables and data migration

All data is stored in the `PersonalPlayerNotesDB` SavedVariables table, containing your reasons, listed players, and minimap/alert settings. On first load, if the legacy `Shitlist` addon and its data are present, you'll be prompted to migrate it into Personal Player Notes.

---

Contributing? See [.github/CONTRIBUTING.md](.github/CONTRIBUTING.md).
