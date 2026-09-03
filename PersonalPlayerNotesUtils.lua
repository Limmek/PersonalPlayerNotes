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
    -- AceGUIContainer-Frame's OnAcquire calls self:Show(), so the frame
    -- starts out visible. Hide it here, BEFORE registering the OnClose
    -- callback below: :Hide() fires OnHide -> Fire("OnClose") synchronously,
    -- and if the release-on-close callback were already registered at that
    -- point it would immediately release this brand-new widget back into
    -- AceGUI's pool (silently, since Release() is otherwise a no-op-looking
    -- call here) before the caller ever gets to configure/show it. A later
    -- :Release() call on the same stale reference (e.g. a guard-clause that
    -- closes a previous popup before opening a new one) would then hit
    -- AceGUI's "Attempt to Release Widget that is already released" error.
    aceGUI:Hide()
    aceGUI:SetCallback("OnClose", function(widget)
        aceGUI:Release()
    end)
    aceGUI:SetLayout("Fill")
    aceGUI:SetStatusText(nil)
    aceGUI.statustext:Hide()
    aceGUI.statustext:GetParent():Hide()
    return aceGUI
end

--[[
    Opens an AceConfig options table (appName) inside a frame built by
    AceGUIDefaults() instead of letting AceConfigDialog:Open() create its own
    bare "Frame" widget - AceConfigDialog's own auto-created frame shows a
    plain, unstyled (black) status bar strip along the bottom that none of
    this addon's other windows have; AceGUIDefaults() hides that.

    AceConfigDialog:Open(appName, container) only reuses/de-dupes via its own
    internal self.OpenFrames[appName] cache when NO container argument is
    passed - passing one every time (as this addon used to) bypassed that
    entirely, so every call created a brand new, untracked frame that never
    got cleaned up (windows stacking endlessly, and :CloseAll() couldn't see
    them to close them either, since it only walks OpenFrames).

    self.customDialogFrames mirrors that same cache, keyed by appName, so
    repeat opens reuse the same frame (refeeding it via AceConfigDialog:Open)
    instead of creating a new one, and the entry is cleared (mirroring
    AceConfigDialog's own internal FrameOnClose behavior) whenever the frame
    closes, so a closed/released frame is never handed back to
    AceConfigDialog:Open() again.
]]
function PersonalPlayerNotes:OpenDialog(appName)
    self.customDialogFrames = self.customDialogFrames or {}
    local frame = self.customDialogFrames[appName]
    if not frame then
        frame = self:AceGUIDefaults()
        frame:SetCallback("OnClose", function(widget)
            if PersonalPlayerNotes.customDialogFrames[appName] == widget then
                PersonalPlayerNotes.customDialogFrames[appName] = nil
            end
            widget:Release()
        end)
        self.customDialogFrames[appName] = frame
    end
    AceConfigDialog:Open(appName, frame)
    frame:Show()
end

--[[
    Closes every dialog opened via OpenDialog() above. AceConfigDialog:CloseAll()
    only knows about frames it created itself (self.OpenFrames), so it can't
    see or close these custom AceGUIDefaults()-backed containers - callers
    that used to rely on :CloseAll() to reset to a clean slate before opening
    a different window need to call this too.
]]
function PersonalPlayerNotes:CloseAllDialogs()
    if not self.customDialogFrames then
        return
    end
    for _, frame in pairs(self.customDialogFrames) do
        frame:Hide()
    end
end

--[[
    Re-feeds a dialog previously opened via OpenDialog(), if it's currently
    open, so option widgets whose displayed value changed elsewhere (e.g.
    the Reasons/Listed Players "Icon" label after picking a new icon in
    OpenIconPicker()) refresh immediately instead of only on the next open.

    AceConfigDialog normally handles this itself via
    AceConfigRegistry:NotifyChange(appName) - it listens for that and
    refeeds any currently open dialog - but only for frames it tracks in
    its own self.OpenFrames cache (see OpenDialog()'s comment above); frames
    passed in as a custom container (ours) are invisible to that mechanism,
    so callers that call AceConfigRegistry:NotifyChange(appName) need to
    call this too.
]]
function PersonalPlayerNotes:RefreshDialog(appName)
    local frame = self.customDialogFrames and self.customDialogFrames[appName]
    if frame then
        AceConfigDialog:Open(appName, frame)
    end
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
