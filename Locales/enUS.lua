local L = LibStub("AceLocale-3.0"):NewLocale("Shitlist", "enUS", true)

-- White        |cffffffff
-- Red          |cffff0000
-- Light Blue   |c0000ffff
-- Yellow       |cffffd700
-- Orange       |cffff8c00
-- Black        |c00000000
-- GOLDENROD    |cFFDAA520
-- TAN          |cFFD2B48C

L["SHITLIST"] = "Shitlist";
L["SHITLIST_DEBUG"] = "|cffff0000[Shitlist]|cffffffff";
L["SHITLIST_PRINT"] = "|cffffd700[Shitlist]|cffffffff";

L["SHITLIST_NA"] = "N/A";

L["SHITLIST_DISABLE"] = "Unloading...";

L["SHITLIST_MENU_TITLE"] = "Shitlist";
L["SHITLIST_MENU_SETTINGS"] = "Options";
L["SHITLIST_MENU_REASONS"] = "Reasons";
L["SHITLIST_MENU_LISTED_PLAYERS"] = "Listed Players";
L["SHITLIST_MENU_PROFILES"] = "Profiles";

L["SHITLIST_CONFIG_LOADING"] = "Loading...";
L["SHITLIST_CONFIG_LOADED"] = "Loaded.";
L["SHITLIST_CONFIG_VERSION"] = "Version:";
L["SHITLIST_CONFIG_REASONS"] = "Reasons:";
L["SHITLIST_CONFIG_LISTEDPLAYERS"] = "Players:";
L["SHITLIST_CONFIG_REFRESH"] = "Reloading configuration...";
L["SHITLIST_CONFIG_CHECK_OLD_DATA"] = "Checking for old player data...";
L["SHITLIST_CONFIG_ADDED_OLD_DATA"] = "Added old player:";
L["SHITLIST_CONFIG_DUPLICATE_DATA"] = "Found duplicate:";

L["SHITLIST_INFO_COMMANDS_TITLE"] = "Commands";
L["SHITLIST_INFO_COMMANDS_DESC"] = "All available slash commands.";
L["SHITLIST_INFO_COMMANDS_1"] = "|cFFD2B48C/sli|cffffffff - Show information.";
L["SHITLIST_INFO_COMMANDS_2"] = "|cFFD2B48C/slo|cffffffff - Change options.";
L["SHITLIST_INFO_COMMANDS_3"] = "|cFFD2B48C/slr|cffffffff - Edit reasons.";
L["SHITLIST_INFO_COMMANDS_4"] = "|cFFD2B48C/slp|cffffffff - Edit player information.";
L["SHITLIST_INFO_COMMANDS_5"] = "|cFFD2B48C/slm|cffffffff - Toggle minimap icon.";
L["SHITLIST_INFO_ABOUT_TITLE"] = "About";
L["SHITLIST_INFO_ABOUT_VERSION"] = "Version";
L["SHITLIST_INFO_ABOUT_AUTHOR"] = "Author";
L["SHITLIST_INFO_ABOUT_CATEGORY"] = "Category";
L["SHITLIST_INFO_ABOUT_LOCALIZATION"] = "Localizations";
L["SHITLIST_INFO_ABOUT_LICENSE"] = "License";
L["SHITLIST_INFO_ABOUT_WEB"] = "Website";

L["SHITLIST_SETTINGS"] = "Options";
L["SHITLIST_SETTINGS_TITLE"] = "Shitlist - Options";
L["SHITLIST_SETTINGS_MINIMAP"] = "Minimap";
L["SHITLIST_SETTINGS_MINIMAP_ICON"] = "Hide the icon.";
L["SHITLIST_SETTINGS_MINIMAP_ICON_DESC"] = "Show or hide the minimap icon.";
L["SHITLIST_SETTINGS_MINIMAP_POS"] = "Position";
L["SHITLIST_SETTINGS_MINIMAP_POS_DESC"] = "Set the position of the minimap icon.";
L["SHITLIST_SETTINGS_ANNOUNCEMENT"] = "Announcement";
L["SHITLIST_SETTINGS_ANNOUNCEMENT_DESC"] = "Set which chat channels you can send player info to.";
L["SHITLIST_SETTINGS_ANNOUNCEMENT_PARY"] = "Party";
L["SHITLIST_SETTINGS_ANNOUNCEMENT_PARY_DESC"] = "";
L["SHITLIST_SETTINGS_ANNOUNCEMENT_RAID"] = "Raid";
L["SHITLIST_SETTINGS_ANNOUNCEMENT_RAID_DESC"] = "";
L["SHITLIST_SETTINGS_ANNOUNCEMENT_INSTANCE"] = "Instance";
L["SHITLIST_SETTINGS_ANNOUNCEMENT_INSTANCE_DESC"] = "";
L["SHITLIST_SETTINGS_ANNOUNCEMENT_GUILD"] = "Guild";
L["SHITLIST_SETTINGS_ANNOUNCEMENT_GUILD_DESC"] = "";
L["SHITLIST_SETTINGS_ANNOUNCEMENT_DELAY"] = "Delay";
L["SHITLIST_SETTINGS_ANNOUNCEMENT_DELAY_DESC"] = "";

L["SHITLIST_SETTINGS_ALERT"] = "Alert";
L["SHITLIST_SETTINGS_ALERT_DESC"] = "Alert when a listed player is found.";
L["SHITLIST_SETTINGS_ALERT_ENABLED"] = "Enabled";
L["SHITLIST_SETTINGS_ALERT_ENABLED_DESC"] = "";
L["SHITLIST_SETTINGS_ALERT_SOUNDS"] = "Sounds";
L["SHITLIST_SETTINGS_ALERT_SOUNDS_DESC"] = "Select the sound to be played.";
L["SHITLIST_SETTINGS_ALERT_DELAY"] = "Delay";
L["SHITLIST_SETTINGS_ALERT_DELAY_DESC"] = "How many seconds to sleep before a new alert for the same player is played.";

L["SHITLIST_REASONS_TITLE"] = "Shitlist - Reasons";
L["SHITLIST_REASONS"] = "Reasons";
L["SHITLIST_REASON"] = "Reason";
L["SHITLIST_REASON_DESCRIPTION"] = "Here you can Edit, Add or Remove differrent reasons.\n";
L["SHITLIST_REASON_REMOVE"] = "Remove Reason";
L["SHITLIST_REASON_REMOVE_CONFIRMATION"] = "Do you really want to remove reason:\n|cffffd700";
L["SHITLIST_REASON_COLOR"] = "Select a color";
L["SHITLIST_REASON_ALERT_ENABLED"] = "Alert"
L["SHITLIST_REASON_ALERT_ENABLED_DESC"] = "Toggle sound effect for all players with this reason."

L["SHITLIST_LISTED_PLAYERS_TITLE"] = "Shitlist - Listed Players";
L["SHITLIST_LISTED_PLAYERS"] = "Listed Players";
L["SHITLIST_LISTED_PLAYER"] = "Listed Player";
L["SHITLIST_LISTED_PLAYER_REMOVE"] = "Remove Player";
L["SHITLIST_LISTED_PLAYER_REMOVE_CONFIRMATION"] = "Do you really want to remove player:\n|cffffd700";
L["SHITLIST_LISTED_PLAYER_NAME"] = "Player Name";
L["SHITLIST_LISTED_PLAYER_REALM"] = "Realm";
L["SHITLIST_LISTED_PLAYER_REASON"] = "Reason";
L["SHITLIST_LISTED_PLAYER_DESCRIPTION"] = "Description";
L["SHITLIST_LISTED_PLAYER_COLOR"] = "Color";
L["SHITLIST_LISTED_PLAYER_ALERT_ENABLED"] = "Alert"
L["SHITLIST_LISTED_PLAYER_ALERT_ENABLED_DESC"] =
"Toggle sound effect for a specific player. If a sound effect is disabled on a pre defined reason then this has no effect."

L["SHITLIST_POPUP_ADD"] = "Add to Shitlist";
L["SHITLIST_POPUP_EDIT"] = "Edit Player";
L["SHITLIST_POPUP_ANNOUNCEMENT"] = "Announcement";
L["SHITLIST_POPUP_NEW_ADDED"] = "Added";

L["SHITLIST_POPUP_ANNOUNCEMENT_GUILD"] = "Guild";
L["SHITLIST_POPUP_ANNOUNCEMENT_PARTY"] = "Party";
L["SHITLIST_POPUP_ANNOUNCEMENT_INSTANCE_CHAT"] = "Instance";
L["SHITLIST_POPUP_ANNOUNCEMENT_RAID"] = "Raid";

L["SHITLIST_MINIMAP_TOOLTIP_TITLE"] = "Shitlist"
L["SHITLIST_MINIMAP_TOOLTIP_RIGHT_CLICK"] = "|cFFD2B48C Right-Click|cff00ff00 to open Blizzard options."
L["SHITLIST_MINIMAP_TOOLTIP_LEFT_CLICK"] = "|cFFD2B48C Left-Click|cff00ff00 to open options."
L["SHITLIST_MINIMAP_TOOLTIP_SHIFT_LEFT_CLICK"] = "|cFFD2B48C SHIFT + Left-Click|cff00ff00 to open reasons."
L["SHITLIST_MINIMAP_TOOLTIP_CTRL_LEFT_CLICK"] = "|cFFD2B48C CTRL + Left-Click|cff00ff00 to open listed players."

L["SHITLIST_CHAT_PLAYER"] = "Player:";
L["SHITLIST_CHAT_REASON"] = "Reason:";
L["SHITLIST_CHAT_DESCRIPTION"] = "Description:";
