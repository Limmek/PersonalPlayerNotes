--[[
    Validates every *.toc file in the repo root.

    Pure Lua 5.1, no WoW client or Ace3 libraries required, so it can run
    identically locally (`lua5.1 Tools/validate-toc.lua`) and in CI.

    Checks performed per .toc file:
      1. Required metadata fields are present (Title, Version, Interface,
         SavedVariables).
      2. The `## Version` field is the packager placeholder `@project-version@`
         (this repo's single source of truth for versioning is the git tag,
         substituted in by BigWigsMods/packager at build time - a hardcoded
         version here would silently stop being the real version).
      3. Every `## Interface*` value is a plausible numeric interface number.
      4. Every non-comment, non-blank line (a file/script reference) points
         at a file that actually exists on disk.
      5. No file is listed more than once (duplicate loads).

    Exits with status 0 if every .toc file is valid, or 1 (printing every
    problem found, not just the first) otherwise.
]]

local REQUIRED_FIELDS = { "Title", "Version", "Interface", "SavedVariables" }
local VERSION_PLACEHOLDER = "@project-version@"

local function scriptDir()
    local source = debug.getinfo(1, "S").source:sub(2)
    return source:match("^(.*)[/\\][^/\\]+$") or "."
end

-- Repo root is the parent of this script's directory (scripts/../).
local repoRoot = scriptDir() .. "/.."

local function fileExists(path)
    local f = io.open(path, "rb")
    if f then
        f:close()
        return true
    end
    return false
end

local function findTocFiles()
    local files = {}
    -- io.popen isn't guaranteed everywhere, but is available on the
    -- GitHub Actions runners and typical local dev machines this targets.
    local list = io.popen('dir /b "' .. repoRoot .. '\\*.toc" 2>nul') -- Windows
    local ok = list and list:read("*l")
    if list then
        if ok then
            files[#files + 1] = ok
            for line in list:lines() do
                files[#files + 1] = line
            end
        end
        list:close()
    end
    if #files == 0 then
        -- Fall back to a POSIX shell (Linux/macOS runners).
        local posixList = io.popen('ls "' .. repoRoot .. '" 2>/dev/null | grep "\\.toc$"')
        if posixList then
            for line in posixList:lines() do
                files[#files + 1] = line
            end
            posixList:close()
        end
    end
    return files
end

local errors = {}

local function fail(tocName, fmt, ...)
    errors[#errors + 1] = string.format("%s: " .. fmt, tocName, ...)
end

local function validateToc(tocName)
    local path = repoRoot .. "/" .. tocName
    local f = io.open(path, "r")
    if not f then
        fail(tocName, "could not open file")
        return
    end

    local fields = {}
    local referencedFiles = {}
    local seen = {}
    local firstLine = true

    for rawLine in f:lines() do
        local line = rawLine:gsub("\r$", "")
        if firstLine then
            -- Strip a leading UTF-8 BOM (EF BB BF), common in files saved by
            -- Windows editors, so it doesn't corrupt parsing of line 1.
            line = line:gsub("^\239\187\191", "")
            firstLine = false
        end

        local field, value = line:match("^##%s*([%w%-]+)%s*:%s*(.-)%s*$")
        if field then
            fields[field] = value
        elseif line:match("^%s*$") or line:match("^##") or line:match("^#") then
            -- blank line, metadata continuation, or plain comment - skip
        else
            local relPath = line:gsub("\\", "/"):match("^%s*(.-)%s*$")
            if relPath ~= "" then
                referencedFiles[#referencedFiles + 1] = relPath
                local key = relPath:lower()
                if seen[key] then
                    fail(tocName, "file is listed more than once: %s", relPath)
                end
                seen[key] = true
            end
        end
    end
    f:close()

    for _, required in ipairs(REQUIRED_FIELDS) do
        if fields[required] == nil then
            fail(tocName, "missing required field: ## %s", required)
        end
    end

    if fields.Version and fields.Version ~= VERSION_PLACEHOLDER then
        fail(
            tocName,
            "## Version should be the packager placeholder '%s', got '%s' "
                .. "(the git tag is the single source of truth for the real version)",
            VERSION_PLACEHOLDER,
            fields.Version
        )
    end

    for field, value in pairs(fields) do
        if field == "Interface" or field:match("^Interface%-") then
            if not value:match("^%d%d%d%d%d+$") then
                fail(tocName, "## %s has a non-numeric/implausible value: '%s'", field, value)
            end
        end
    end

    for _, relPath in ipairs(referencedFiles) do
        local fullPath = repoRoot .. "/" .. relPath
        if not fileExists(fullPath) then
            fail(tocName, "referenced file not found: %s", relPath)
        end
    end
end

local tocFiles = findTocFiles()

if #tocFiles == 0 then
    print("No .toc files found in " .. repoRoot)
    os.exit(1)
end

for _, tocName in ipairs(tocFiles) do
    print("Validating " .. tocName)
    validateToc(tocName)
end

if #errors > 0 then
    print(string.format("\n%d problem(s) found:\n", #errors))
    for _, err in ipairs(errors) do
        print("  - " .. err)
    end
    os.exit(1)
end

print("\nAll .toc files are valid.")
