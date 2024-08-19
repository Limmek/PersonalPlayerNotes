local L = LibStub("AceLocale-3.0"):NewLocale("PersonalPlayerNotes", "enUS", true)

-- White        |cffffffff
-- Red          |cffff0000
-- Light Blue   |c0000ffff
-- Yellow       |cffffd700
-- Orange       |cffff8c00
-- Black        |c00000000
-- GOLDENROD    |cFFDAA520
-- TAN          |cFFD2B48C

L["PPN"] = "Personal Player Notes";
L["PPN_DEBUG"] = "|cffff0000[Personal Player Notes]|cffffffff";
L["PPN_PRINT"] = "|cffffd700[Personal Player Notes]|cffffffff";

L["PPN_NA"] = "N/A";

L["PPN_DISABLE"] = "Unloading...";

L["PPN_MENU_TITLE"] = "Personal Player Notes";
L["PPN_MENU_SETTINGS"] = "Options";
L["PPN_MENU_REASONS"] = "Reasons";
L["PPN_MENU_LISTED_PLAYERS"] = "Listed Players";
L["PPN_MENU_PROFILES"] = "Profiles";

L["PPN_CONFIG_LOADING"] = "Loading...";
L["PPN_CONFIG_LOADED"] = "Loaded.";
L["PPN_CONFIG_VERSION"] = "Version:";
L["PPN_CONFIG_REASONS"] = "Reasons:";
L["PPN_CONFIG_LISTEDPLAYERS"] = "Players:";
L["PPN_CONFIG_REFRESH"] = "Reloading configuration...";
L["PPN_CONFIG_CHECK_OLD_DATA"] = "Checking for old player data...";
L["PPN_CONFIG_MIGRATE_OLD_DATA"] = "Migrating profiles from Shitlist.";
L["PPN_CONFIG_ADDED_OLD_DATA"] = "Added old player:";
L["PPN_CONFIG_DUPLICATE_DATA"] = "Found duplicate:";
L["PPN_CONFIG_MIGRATE"] = "Do you want to migrate profiles from Shitlist?";
L["PPN_CONFIG_MIGRATE_YES"] = "Yes";
L["PPN_CONFIG_MIGRATE_NO"] = "No";
L["PPN_CONFIG_MIGRATE_DONE"] = "Profiles from Shitlist has been migrated.";

L["PPN_INFO_COMMANDS_TITLE"] = "Commands";
L["PPN_INFO_COMMANDS_DESC"] = "All available slash commands.";
L["PPN_INFO_COMMANDS_1"] = "|cFFD2B48C/ppn|cffffffff - Open Blizzard options.";
L["PPN_INFO_COMMANDS_2"] = "|cFFD2B48C/ppno|cffffffff or |cFFD2B48C/ppnoptions|cffffffff - Change options.";
L["PPN_INFO_COMMANDS_3"] = "|cFFD2B48C/ppnr|cffffffff or |cFFD2B48C/ppnreasons|cffffffff - Edit reasons.";
L["PPN_INFO_COMMANDS_4"] = "|cFFD2B48C/ppnp|cffffffff or |cFFD2B48C/ppnplayers|cffffffff - Edit player information.";
L["PPN_INFO_COMMANDS_5"] = "|cFFD2B48C/ppnm|cffffffff or |cFFD2B48C/ppnminimap|cffffffff - Toggle minimap icon.";
L["PPN_INFO_ABOUT_TITLE"] = "About";
L["PPN_INFO_ABOUT_VERSION"] = "Version";
L["PPN_INFO_ABOUT_AUTHOR"] = "Author";
L["PPN_INFO_ABOUT_CATEGORY"] = "Category";
L["PPN_INFO_ABOUT_LOCALIZATION"] = "Localizations";
L["PPN_INFO_ABOUT_LICENSE"] = "License";
L["PPN_INFO_ABOUT_WEB"] = "Website";

L["PPN_SETTINGS"] = "Options";
L["PPN_SETTINGS_TITLE"] = "Personal Player Notes - Options";
L["PPN_SETTINGS_MINIMAP"] = "Minimap";
L["PPN_SETTINGS_MINIMAP_ICON"] = "Hide the icon.";
L["PPN_SETTINGS_MINIMAP_ICON_DESC"] = "Show or hide the minimap icon.";
L["PPN_SETTINGS_MINIMAP_POS"] = "Position";
L["PPN_SETTINGS_MINIMAP_POS_DESC"] = "Set the position of the minimap icon.";

L["PPN_SETTINGS_ALERT"] = "Alert";
L["PPN_SETTINGS_ALERT_DESC"] = "Alert when a listed player is found.";
L["PPN_SETTINGS_ALERT_ENABLED"] = "Enabled";
L["PPN_SETTINGS_ALERT_ENABLED_DESC"] = "";
L["PPN_SETTINGS_ALERT_SOUNDS"] = "Sounds";
L["PPN_SETTINGS_ALERT_SOUNDS_DESC"] = "Select the sound to be played.";
L["PPN_SETTINGS_ALERT_DELAY"] = "Delay";
L["PPN_SETTINGS_ALERT_DELAY_DESC"] = "How many seconds to sleep before a new alert for the same player is played.";

L["PPN_REASONS_TITLE"] = "Personal Player Notes - Reasons";
L["PPN_REASONS"] = "Reasons";
L["PPN_REASON"] = "Reason";
L["PPN_REASON_DESCRIPTION"] = "Here you can Edit, Add or Remove differrent reasons.\n";
L["PPN_REASON_REMOVE"] = "Remove Reason";
L["PPN_REASON_REMOVE_CONFIRMATION"] = "Do you really want to remove reason:\n|cffffd700";
L["PPN_REASON_COLOR"] = "Select a color";
L["PPN_REASON_ALERT_ENABLED"] = "Alert"
L["PPN_REASON_ALERT_ENABLED_DESC"] = "Toggle sound effect for all players with this reason."
L["PPN_DEFAULT_REASON"] = "None";

L["PPN_LISTED_PLAYERS_TITLE"] = "Personal Player Notes - Listed Players";
L["PPN_LISTED_PLAYERS"] = "Listed Players";
L["PPN_LISTED_PLAYER"] = "Listed Player";
L["PPN_LISTED_PLAYER_REMOVE"] = "Remove Player";
L["PPN_LISTED_PLAYER_REMOVE_CONFIRMATION"] = "Do you really want to remove player:\n|cffffd700";
L["PPN_LISTED_PLAYER_NAME"] = "Player Name";
L["PPN_LISTED_PLAYER_REALM"] = "Realm";
L["PPN_LISTED_PLAYER_REASON"] = "Reason";
L["PPN_LISTED_PLAYER_DESCRIPTION"] = "Description";
L["PPN_LISTED_PLAYER_COLOR"] = "Color";
L["PPN_LISTED_PLAYER_ALERT_ENABLED"] = "Alert"
L["PPN_LISTED_PLAYER_ALERT_ENABLED_DESC"] =
"Toggle sound effect for a specific player. If a sound effect is disabled on a pre defined reason then this has no effect."
L["PPN_LISTED_PLAYERS_EXAMPLE_NAME"] = "Example";
L["PPN_LISTED_PLAYERS_EXAMPLE_REALM"] = "Silvermoon";
L["PPN_LISTED_PLAYERS_EXAMPLE_DESC"] = "None";

L["PPN_POPUP_ADD"] = "Add Player";
L["PPN_POPUP_EDIT"] = "Edit Player";
L["PPN_POPUP_NEW_ADDED"] = "Added";

L["PPN_MINIMAP_TOOLTIP_TITLE"] = "Personal Player Notes"
L["PPN_MINIMAP_TOOLTIP_RIGHT_CLICK"] = "|cFFD2B48C Right-Click|cff00ff00 to open Blizzard options."
L["PPN_MINIMAP_TOOLTIP_LEFT_CLICK"] = "|cFFD2B48C Left-Click|cff00ff00 to open options."
L["PPN_MINIMAP_TOOLTIP_SHIFT_LEFT_CLICK"] = "|cFFD2B48C SHIFT + Left-Click|cff00ff00 to open reasons."
L["PPN_MINIMAP_TOOLTIP_CTRL_LEFT_CLICK"] = "|cFFD2B48C CTRL + Left-Click|cff00ff00 to open listed players."
