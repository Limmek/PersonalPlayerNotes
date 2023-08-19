std = "min"
globals = {
    "UnitIsPlayer",
    "RegisterChatCommand",
    "UIDROPDOWNMENU_MAXBUTTONS",
    "ChatFontNormal",
    "TooltipDataProcessor",
    "UIDROPDOWNMENU_MENU_LEVEL",
    "ShitlistSettings",
    "Settings",
    "NOT_BOUND",
    "GetLocale",
    "UIDropDownMenu_AddButton",
    "tremove",
    "DEFAULT_CHAT_FRAME",
    "FONT_COLOR_CODE_CLOSE",
    "GetCursorPosition",
    "InterfaceOptions_AddCategory",
    "Enum",
    "GetItemInfo",
    "UIDropDownMenu_CreateInfo",
    "SlashCmdList",
    "AddDoubleLine",
    "GameTooltip",
    "NORMAL_FONT_COLOR",
    "_L",
    "UIParentLoadAddOn",
    "SetTooltipMoney",
    "CreateFrame",
    "ACCEPT",
    "hash_SlashCmdList",
    "RegisterCallback",
    "NORMAL_FONT_COLOR_CODE",
    "GameFontNormalSmall",
    "OKAY",
    "NUM_CHAT_WINDOWS",
    "FriendsFrame",
    "GameFontHighlightLarge",
    "GetRealmName",
    "UnitName",
    "GetUnit",
    "CLOSE",
    "geterrorhandler",
    "testDB",
    "OpacitySliderFrame",
    "IsSecureCmd",
    "Shitlist",
    "AddLine",
    "SELECTED_CHAT_FRAME",
    "GameFontHighlightSmall",
    "SetDesaturation",
    "ColorPickerFrame",
    "ChatEdit_GetActiveWindow",
    "UnitPopupMenus",
    "ItemRefTooltip",
    "IsControlKeyDown",
    "print",
    "LibStub",
    "CANCEL",
    "SHITLIST_ID",
    "GetMouseFocus",
    "ShitlistDB",
    "IsShiftKeyDown",
    "GameFontDisableSmall",
    "UnitPopup_ShowMenu",
    "InterfaceOptionsFrame_OpenToCategory",
    "GameFontNormal",
    "ReloadUI",
    "pairs",
    "C_Timer",
    "GameFontHighlight",
    "AuctionDB",
    "_G",
    "tinsert",
    "UIDropDownMenu_AddSeparator",
    "time",
    "EasyMenu",
    "UIDropDownMenu_SetWidth",
    "UIDropDownMenu_SetText",
    "UIDropDownMenu_Initialize",
    "CloseDropDownMenus",
    "ToggleDropDownMenu",
    "PlayerFrameDropDown",
    "UIDropDownMenu_GetText",
    "ChatFrame1EditBox",
    "TargetFrame",
    "PlayerFrame",
    "UIDropDownMenu_GetCurrentDropDown",
    "UISpecialFrames",
    "ChatFrame1",
    "GameTooltip_SetDefaultAnchor",
    "HIGHLIGHT_FONT_COLOR",
    "WorldFrame",
    "TooltipBackdropTemplateMixin",
    "GameMenuFrame",
    "UIDROPDOWNMENU_INIT_MENU",
    "UIDROPDOWNMENU_MENU_VALUE"
}
max_line_length = 132
ignore = {
    "211/_.*",
    "211/L",
    "212/_.*",
    -- "11./SLASH_.*", -- Setting an undefined (Slash handler) global variable
    -- "11./BINDING_.*", -- Setting an undefined (Keybinding header) global variable
    -- "113/LE_.*", -- Accessing an undefined (Lua ENUM type) global variable
    -- "113/NUM_LE_.*", -- Accessing an undefined (Lua ENUM type) global variable
    "211", -- Unused local variable
    -- "211/L", -- Unused local variable "CL"
    -- "211/CL", -- Unused local variable "CL"
    -- "212", -- Unused argument
    -- "213", -- Unused loop variable
    -- "231", -- Set but never accessed
    -- "311", -- Value assigned to a local variable is unused
    -- "314", -- Value of a field in a table literal is unused
    -- "42.", -- Shadowing a local variable, an argument, a loop variable.
    -- "43.", -- Shadowing an upvalue, an upvalue argument, an upvalue loop variable.
    -- "542", -- An empty if branch
    -- "611", -- A line consists of nothing but whitespace.
    -- "612", -- A line contains trailing whitespace.
    -- "613", -- Trailing whitespace in a string.
    -- "614", -- Trailing whitespace in a comment.
    -- "631" -- max_line_length
}
self = false

-- Allow unused arguments.
unused_args = false

-- Disable line length limits.
-- max_line_length = false
-- max_code_line_length = false
-- max_string_line_length = false
-- max_comment_line_length = false

exclude_files = { "**/Libs", "Libs/*.lua", ".luacheckrc", "*" }
include_files = { "Shitlist.lua", "ShitlistConfig.lua", "ShitlistUtils.lua", "Locales/*.lua" }
