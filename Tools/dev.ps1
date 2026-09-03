[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $RepoRoot

$LuaFiles = @(
    'PersonalPlayerNotes.lua'
    'PersonalPlayerNotesConfig.lua'
    'PersonalPlayerNotesUtils.lua'
    'Sounds/Manifest.lua'
    'Tests/test_utils.lua'
    'Tests/test_config.lua'
    'Tests/test_main.lua'
    'Tests/support/bootstrap.lua'
    'Locales/enUS.lua'
    'Locales/zhCN.lua'
    'Tools/validate-toc.lua'
    'Tools/generate-sounds-manifest.lua'
)

$TestFiles = @(
    'Tests/test_utils.lua'
    'Tests/test_config.lua'
    'Tests/test_main.lua'
)

function Resolve-CommandPath {
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Names,

        [string[]] $CandidatePaths = @(),

        [Parameter(Mandatory = $true)]
        [string] $MissingMessage
    )

    foreach ($candidate in $CandidatePaths) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    foreach ($name in $Names) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command) {
            if ($command.Path) {
                return $command.Path
            }

            if ($command.Source) {
                return $command.Source
            }

            return $command.Name
        }
    }

    throw $MissingMessage
}

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $true)]
        [scriptblock] $Action
    )

    Write-Host ''
    Write-Host "==> $Name"
    & $Action
}

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ToolPath,

        [Parameter(Mandatory = $true)]
        [string[]] $Arguments
    )

    & $ToolPath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$ToolPath failed with exit code $LASTEXITCODE."
    }
}

$StyLua = Resolve-CommandPath `
    -Names @('stylua.exe', 'stylua') `
    -CandidatePaths @(
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages\JohnnyMorganz.StyLua_Microsoft.Winget.Source_8wekyb3d8bbwe\stylua.exe')
    ) `
    -MissingMessage @'
StyLua was not found.
Install it with:
  winget install --id JohnnyMorganz.StyLua --version 2.5.2 -e
Or set STYLUA to the full path of the executable.
'@

$Luacheck = Resolve-CommandPath `
    -Names @('luacheck.exe', 'luacheck') `
    -CandidatePaths @(
        (Join-Path $RepoRoot 'Tools\luacheck.exe')
    ) `
    -MissingMessage @'
Luacheck was not found.
Install it or place luacheck.exe on PATH.
If you already have a local luacheck binary, point LUACHECK at it.
'@

$Lua = Resolve-CommandPath `
    -Names @('lua5.1.exe', 'lua5.1', 'lua.exe', 'lua') `
    -CandidatePaths @(
        'C:\Program Files (x86)\Lua\5.1\lua.exe',
        'C:\Program Files\Lua\5.1\lua.exe'
    ) `
    -MissingMessage @'
Lua 5.1 was not found.
Install Lua 5.1 or expose lua5.1/lua on PATH.
'@

Invoke-Step -Name 'Formatting with StyLua' -Action {
    Invoke-CheckedCommand -ToolPath $StyLua -Arguments $LuaFiles
}

Invoke-Step -Name 'Linting with Luacheck' -Action {
    Invoke-CheckedCommand -ToolPath $Luacheck -Arguments @('--no-color', '-q', '.')
}

Invoke-Step -Name 'Running unit tests' -Action {
    foreach ($testFile in $TestFiles) {
        Write-Host "-- $testFile --"
        Invoke-CheckedCommand -ToolPath $Lua -Arguments @($testFile)
    }
}

Invoke-Step -Name 'Validating addon metadata' -Action {
    Invoke-CheckedCommand -ToolPath $Lua -Arguments @('Tools/validate-toc.lua')
}

Invoke-Step -Name 'Checking Sounds/Manifest.lua' -Action {
    Invoke-CheckedCommand -ToolPath $Lua -Arguments @('Tools/generate-sounds-manifest.lua', '--check')
}

Invoke-Step -Name 'Building local package' -Action {
    $ReleaseDir = Join-Path $RepoRoot '.release'
    $ReleaseScript = Join-Path $ReleaseDir 'release.sh'

    if (-not (Test-Path -LiteralPath $ReleaseScript)) {
        New-Item -ItemType Directory -Path $ReleaseDir -Force | Out-Null
        $ReleaseUri = 'https://raw.githubusercontent.com/BigWigsMods/packager/v2.5.1/release.sh'
        Write-Host "Fetching release script from $ReleaseUri"
        Invoke-WebRequest -UseBasicParsing -Uri $ReleaseUri -OutFile $ReleaseScript
    }

    $Bash = Resolve-CommandPath `
        -Names @('bash.exe', 'bash') `
        -CandidatePaths @(
            'C:\Program Files\Git\bin\bash.exe',
            'C:\Program Files\Git\usr\bin\bash.exe'
        ) `
        -MissingMessage @'
Bash was not found.
Install Git for Windows or make bash.exe available on PATH.
The local package build uses the BigWigsMods packager release script.
'@

    $SevenZip = Resolve-CommandPath `
        -Names @('7z.exe', '7z') `
        -CandidatePaths @(
            'C:\Program Files\7-Zip\7z.exe',
            'C:\Program Files (x86)\7-Zip\7z.exe'
        ) `
        -MissingMessage @'
7-Zip was not found.
Install 7-Zip so the local package build can create zip archives.
'@

    $TempShimDir = Join-Path ([System.IO.Path]::GetTempPath()) 'PersonalPlayerNotes-dev-shims'
    New-Item -ItemType Directory -Path $TempShimDir -Force | Out-Null

    $ZipShimScript = Join-Path $TempShimDir 'zip-shim.sh'
    $zipShimContent = @'
zip() {
    local archive=""
    local -a inputs=()
    local -a excludes=()
    local exclude_mode=0

    while [ $# -gt 0 ]; do
        case "$1" in
            -X|-r|-q)
                ;;
            -x)
                exclude_mode=1
                ;;
            *)
                if [ -z "$archive" ]; then
                    archive="$1"
                elif [ "$exclude_mode" -eq 1 ]; then
                    excludes+=("-x!$1")
                else
                    inputs+=("$1")
                fi
                ;;
        esac
        shift
    done

    if [ -z "$archive" ] || [ ${#inputs[@]} -eq 0 ]; then
        echo 'zip shim expected an archive path and at least one input path.' >&2
        return 1
    fi

    '__SEVENZIP__' a -tzip -mx=9 -r "$archive" "${inputs[@]}" "${excludes[@]}"
}
'@.Replace('__SEVENZIP__', $SevenZip)

    Set-Content -LiteralPath $ZipShimScript -Value $zipShimContent -Encoding ASCII

    $ZipShimBashPath = (Resolve-Path -LiteralPath $ZipShimScript).Path -replace '\\', '/'
    if ($ZipShimBashPath -match '^([A-Za-z]):/(.*)$') {
        $ZipShimBashPath = '/' + $matches[1].ToLower() + '/' + $matches[2]
    }

    $env:BASH_ENV = $ZipShimBashPath

    $Svn = Resolve-CommandPath `
        -Names @('svn.exe', 'svn') `
        -CandidatePaths @(
            'C:\Program Files\SlikSvn\bin\svn.exe',
            'C:\Program Files\Subversion\bin\svn.exe',
            'C:\Program Files (x86)\SlikSvn\bin\svn.exe'
        ) `
        -MissingMessage @'
svn was not found.
Install a Subversion CLI (for example Slik Subversion) so the packager can fetch svn externals.
'@

    $SvnDir = Split-Path -Parent $Svn
    if ($env:PATH -notlike "*$SvnDir*") {
        $env:PATH = "$SvnDir;$env:PATH"
    }

    Invoke-CheckedCommand -ToolPath $Bash -Arguments @($ReleaseScript, '-d', '-p', '0', '-w', '0', '-a', '0', '-m', '.pkgmeta')
}

Write-Host ''
Write-Host 'All local checks completed successfully.'