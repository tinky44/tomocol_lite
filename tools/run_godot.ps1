param(
    [string]$GodotExe = "",
    [switch]$Headless,
    [switch]$Quit,
    [string]$LogPrefix = "godot"
)

function Resolve-ExeCandidate {
    param(
        [string]$CandidatePath
    )

    if ([string]::IsNullOrWhiteSpace($CandidatePath)) {
        return $null
    }

    try {
        $item = Get-Item -LiteralPath $CandidatePath -ErrorAction Stop
    }
    catch {
        return $null
    }

    if ($item -is [System.IO.FileInfo] -and $item.Extension -ieq ".exe") {
        return $item.FullName
    }

    if ($item -is [System.IO.DirectoryInfo]) {
        $consoleExe = Get-ChildItem -LiteralPath $item.FullName -Filter "Godot*_console.exe" -File -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($consoleExe) {
            return $consoleExe.FullName
        }

        $guiExe = Get-ChildItem -LiteralPath $item.FullName -Filter "Godot*.exe" -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notlike "*_console.exe" } |
            Select-Object -First 1
        if ($guiExe) {
            return $guiExe.FullName
        }
    }

    return $null
}

function Resolve-GodotExe {
    param(
        [string]$PreferredPath
    )

    $candidates = @()

    if (-not [string]::IsNullOrWhiteSpace($PreferredPath)) {
        $candidates += $PreferredPath
    }

    if (-not [string]::IsNullOrWhiteSpace($env:GODOT_EXE)) {
        $candidates += $env:GODOT_EXE
    }

    $searchRoots = @(
        (Join-Path $env:USERPROFILE "Downloads"),
        (Join-Path $env:USERPROFILE "Desktop"),
        "C:\Program Files",
        "C:\Program Files (x86)"
    )

    foreach ($root in $searchRoots) {
        if (-not (Test-Path -LiteralPath $root)) {
            continue
        }

        $consoleMatches = Get-ChildItem -Path $root -Filter "Godot*_console.exe" -File -Recurse -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty FullName
        if ($consoleMatches) {
            $candidates += $consoleMatches
        }

        $guiMatches = Get-ChildItem -Path $root -Filter "Godot*.exe" -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notlike "*_console.exe" } |
            Select-Object -ExpandProperty FullName
        if ($guiMatches) {
            $candidates += $guiMatches
        }
    }

    foreach ($candidate in $candidates | Select-Object -Unique) {
        $resolvedCandidate = Resolve-ExeCandidate -CandidatePath $candidate
        if (-not [string]::IsNullOrWhiteSpace($resolvedCandidate)) {
            return $resolvedCandidate
        }
    }

    throw "Godot executable was not found. Set -GodotExe or GODOT_EXE."
}

$repoRoot = Split-Path $PSScriptRoot -Parent
$projectPath = Join-Path $repoRoot "godot-project"
$runtimeRoot = Join-Path $repoRoot "artifacts\godot-runtime"
$godotRoamingDir = Join-Path $runtimeRoot "AppData\Roaming"
$godotLocalDir = Join-Path $runtimeRoot "AppData\Local"
$godotTempDir = Join-Path $runtimeRoot "Temp"
$godotLogDir = Join-Path $runtimeRoot "logs"

$resolvedGodotExe = Resolve-GodotExe -PreferredPath $GodotExe
$safeLogPrefix = ($LogPrefix -replace '[<>:"/\\|?*]', '_')
$logTimestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFilePath = Join-Path $godotLogDir "$safeLogPrefix`_$logTimestamp.log"

New-Item -ItemType Directory -Force -Path $godotRoamingDir | Out-Null
New-Item -ItemType Directory -Force -Path $godotLocalDir | Out-Null
New-Item -ItemType Directory -Force -Path $godotTempDir | Out-Null
New-Item -ItemType Directory -Force -Path $godotLogDir | Out-Null

Write-Host "USING_GODOT_EXE=$resolvedGodotExe"
Write-Host "USING_GODOT_LOG_FILE=$logFilePath"

$arguments = [System.Collections.Generic.List[string]]::new()
if ($Headless) {
    $arguments.Add("--headless")
}
$arguments.AddRange([string[]]@(
    "--path", $projectPath,
    "--log-file", $logFilePath
))
if ($Quit) {
    $arguments.Add("--quit")
}

$originalEnv = @{
    "APPDATA" = $env:APPDATA
    "LOCALAPPDATA" = $env:LOCALAPPDATA
    "TEMP" = $env:TEMP
    "TMP" = $env:TMP
}

$env:APPDATA = $godotRoamingDir
$env:LOCALAPPDATA = $godotLocalDir
$env:TEMP = $godotTempDir
$env:TMP = $godotTempDir

$exitCode = 1
try {
    & $resolvedGodotExe @arguments
    $exitCode = $LASTEXITCODE
}
finally {
    foreach ($key in $originalEnv.Keys) {
        if ($null -eq $originalEnv[$key]) {
            Remove-Item -Path "Env:$key" -ErrorAction SilentlyContinue
        }
        else {
            Set-Item -Path "Env:$key" -Value $originalEnv[$key]
        }
    }
}

exit $exitCode

