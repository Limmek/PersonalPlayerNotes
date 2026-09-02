local personalPlayerNotes = ...
local L = LibStub("AceLocale-3.0"):GetLocale(personalPlayerNotes, true)
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- Current SavedVariables schema version. Bump this and extend
-- MigrateSavedVariablesSchema() whenever the profile table shape changes
-- in a way that requires converting existing user data.
PersonalPlayerNotes.SCHEMA_VERSION = 2

--#region Client feature detection

--[[
    Client capabilities are feature-detected instead of branched on
    WOW_PROJECT_ID/flavor, since Classic clients have progressively picked up
    modern Retail APIs and this avoids hardcoding assumptions per client.
]]
function PersonalPlayerNotes:HasModernMenuAPI()
    return type(Menu) == "table" and type(Menu.ModifyMenu) == "function"
end

function PersonalPlayerNotes:HasModernTooltipAPI()
    return type(TooltipDataProcessor) == "table"
        and type(TooltipDataProcessor.AddTooltipPostCall) == "function"
        and type(Enum) == "table"
        and Enum.TooltipDataType ~= nil
end

function PersonalPlayerNotes:HasModernSettingsAPI()
    return type(Settings) == "table" and type(Settings.OpenToCategory) == "function"
end

--[[
    Some Classic clients don't expose the C_AddOns/C_UI namespaces yet, still
    relying on the older global LoadAddOn/DisableAddOn/ReloadUI functions.
    Confirmed via live testing on Wrath Classic.
]]
function PersonalPlayerNotes:HasModernAddOnAPI()
    return type(C_AddOns) == "table"
        and type(C_AddOns.LoadAddOn) == "function"
        and type(C_AddOns.DisableAddOn) == "function"
end

function PersonalPlayerNotes:HasModernUIReloadAPI()
    return type(C_UI) == "table" and type(C_UI.Reload) == "function"
end

--[[
    Patch 12.0.0 (Midnight) introduced "secret values": some unit tokens
    (e.g. those tied to world cursor tooltips over terrain/world objects) can
    no longer be inspected by insecure addon code. Passing one to an API like
    UnitIsPlayer() throws a hard Lua error ("Secret values are only allowed
    during untainted execution for this argument") instead of just returning
    a value, so it must be checked for and skipped rather than caught after
    the fact. issecretvalue() is the client API added to detect this; it may
    not exist on older clients, hence the feature check.
    https://warcraft.wiki.gg/wiki/Secret_Values
]]
function PersonalPlayerNotes:IsSecretUnit(unit)
    return type(issecretvalue) == "function" and issecretvalue(unit) == true
end

--[[
    Opens the Blizzard options window to this addon's category, falling back
    to opening the Ace3 config dialog directly on clients without the modern
    Settings API.

    Settings.OpenToCategory() expects the numeric/category-object ID returned
    by AceConfigDialog:AddToBlizOptions() (stored in
    self.blizOptionsCategoryID during OnInitialize), NOT the addon name
    string - passing the string throws "bad argument #1 to
    'OpenSettingsPanel' (outside of expected range)" on modern clients.
]]
function PersonalPlayerNotes:OpenBlizzardOptions()
    if self:HasModernSettingsAPI() and self.blizOptionsCategoryID then
        Settings.OpenToCategory(self.blizOptionsCategoryID)
    else
        AceConfigDialog:Open("PersonalPlayerNotesSettings Info")
    end
end

--#endregion

--#region SavedVariables migration

--[[
    Parses a legacy Shitlist "Name-Realm" key into separate name/realm values.
    Kept as a pure string function (no SavedVariables/WoW API access) so it
    can be unit tested outside of WoW, see Tests/test_utils.lua.
]]
function PersonalPlayerNotes:ParseLegacyPlayerKey(key)
    if type(key) ~= "string" then
        return nil, nil
    end
    return key:match("([^-]+)-([^-]+)")
end

--[[
    Runs once per login after the AceDB profile is loaded. AceDB-3.0 already
    fills in missing fields from PersonalPlayerNotes.defaults, so this only
    needs to handle actual structural changes between schema versions.
]]
function PersonalPlayerNotes:MigrateSavedVariablesSchema()
    local profile = self.db.profile
    local fromVersion = profile.schemaVersion or 0

    if fromVersion < 1 then
        -- Initial schema version, nothing to convert yet.
    end

    if fromVersion < 2 then
        -- alert.sound used to be a 1-4 index into a per-profile alert.sounds
        -- array; sounds are now selected by filename instead, sourced from
        -- the global PersonalPlayerNotes.SoundManifest (see
        -- Sounds/Manifest.lua) rather than stored per-profile. Reset
        -- everyone to the new default sound rather than trying to map old
        -- indices to filenames, and drop the now-unused sounds array.
        -- (Not read from PersonalPlayerNotes.defaults here: this file's own
        -- unit tests load it in isolation, without PersonalPlayerNotesConfig.lua.)
        profile.alert.sound = "default.mp3"
        profile.alert.sounds = nil
        -- Superseded by alert.customSounds (a list the user can add/remove
        -- entries from) before this ever shipped, so there's no old value to
        -- carry over - just make sure both new fields exist.
        profile.alert.customSoundFile = nil
        profile.alert.customSounds = profile.alert.customSounds or {}
        profile.alert.newCustomSound = profile.alert.newCustomSound or ""
    end

    profile.schemaVersion = PersonalPlayerNotes.SCHEMA_VERSION
end

--#endregion

--#region Addon metadata

--[[
    All of the following read a single field from the .toc's metadata via
    C_AddOns.GetAddOnMetadata(), falling back to L["PPN_NA"] if the field is
    missing (e.g. an optional .toc field like X-Website wasn't set).
]]

--[[
    Returns the addon's Version .toc field, wrapped in tostring() since
    GetAddOnMetadata() can hand back a bare number for numeric-looking
    version strings.
]]
function PersonalPlayerNotes:GetVersion()
    return tostring(C_AddOns.GetAddOnMetadata(personalPlayerNotes, "Version")) or L["PPN_NA"]
end

--[[
    Returns the addon's Title .toc field.
]]
function PersonalPlayerNotes:GetTitle()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "Title") or L["PPN_NA"]
end

--[[
    Returns the addon's Author .toc field.
]]
function PersonalPlayerNotes:GetAuthor()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "Author") or L["PPN_NA"]
end

--[[
    Returns the addon's Notes .toc field.
]]
function PersonalPlayerNotes:GetNotes()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "Notes") or L["PPN_NA"]
end

--[[
    Returns the addon's X-Localizations .toc field.
]]
function PersonalPlayerNotes:GetLocalizations()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "X-Localizations") or L["PPN_NA"]
end

--[[
    Returns the addon's X-Category .toc field.
]]
function PersonalPlayerNotes:GetCategory()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "X-Category") or L["PPN_NA"]
end

--[[
    Returns the addon's X-Website .toc field.
]]
function PersonalPlayerNotes:GetWebsite()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "X-Website") or L["PPN_NA"]
end

--[[
    Returns the addon's X-License .toc field.
]]
function PersonalPlayerNotes:GetLicense()
    return C_AddOns.GetAddOnMetadata(personalPlayerNotes, "X-License") or L["PPN_NA"]
end

--#endregion

--[[
    Creates a bare AceGUI-3.0 Frame widget preconfigured the way this addon's
    dropdown/minimap-icon "Add"/"Edit" popups expect it: releases itself on
    close, fills its container, and hides the (unused) status bar text/frame.
    Callers are expected to still call :SetTitle() before showing it.
]]
function PersonalPlayerNotes:AceGUIDefaults()
    local aceGUI = LibStub("AceGUI-3.0"):Create("Frame")
    aceGUI:SetCallback("OnClose", function(widget)
        aceGUI:Release()
    end)
    aceGUI:SetLayout("Fill")
    aceGUI:SetStatusText(nil)
    aceGUI.statustext:Hide()
    aceGUI.statustext:GetParent():Hide()
    aceGUI:Hide()
    return aceGUI
end

--[[
    Prints to the default chat frame, prefixed with L["PPN_DEBUG"] instead of
    L["PPN_PRINT"] when debug mode is on (self.db.profile.debug). Safe to
    call before self.db exists (e.g. very early during load).
]]
function PersonalPlayerNotes:Print(...)
    if self.db and self.db.profile.debug then
        return print(L["PPN_DEBUG"], ...)
    end
    return print(L["PPN_PRINT"], ...)
end

--[[
    Forwards to Print() only while debug mode is enabled; a no-op otherwise.
    Used for verbose logging that shouldn't show up for regular users.
]]
function PersonalPlayerNotes:PrintDebug(...)
    if self.db and self.db.profile.debug then
        self:Print(...)
    end
end
