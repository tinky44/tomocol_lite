param(
    [string]$GodotExe = "",
    [string]$OutputDir = "",
    [string]$Prefix = "capture",
    [int]$Frames = 12,
    [int]$Fps = 10,
    [switch]$CreatorCapture,
    [string[]]$UserArgs = @()
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

if ($Frames -lt 1) {
    throw "-Frames must be 1 or greater."
}

if ($Fps -lt 1) {
    throw "-Fps must be 1 or greater."
}

$repoRoot = Split-Path $PSScriptRoot -Parent
$projectPath = Join-Path $repoRoot "godot-project"
$runtimeRoot = Join-Path $repoRoot "artifacts\godot-runtime"
$godotRoamingDir = Join-Path $runtimeRoot "AppData\Roaming"
$godotLocalDir = Join-Path $runtimeRoot "AppData\Local"
$godotTempDir = Join-Path $runtimeRoot "Temp"
$godotLogDir = Join-Path $runtimeRoot "logs"

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $repoRoot "screen_shots"
}

$resolvedGodotExe = Resolve-GodotExe -PreferredPath $GodotExe
$safePrefix = ($Prefix -replace '[<>:"/\\|?*]', '_')
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$captureBaseName = "$safePrefix`_$timestamp"
$captureRequestPath = Join-Path $OutputDir "$captureBaseName.png"
$logFilePath = Join-Path $godotLogDir "$captureBaseName.log"

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
New-Item -ItemType Directory -Force -Path $godotRoamingDir | Out-Null
New-Item -ItemType Directory -Force -Path $godotLocalDir | Out-Null
New-Item -ItemType Directory -Force -Path $godotTempDir | Out-Null
New-Item -ItemType Directory -Force -Path $godotLogDir | Out-Null

$arguments = [System.Collections.Generic.List[string]]::new()
$arguments.AddRange([string[]]@(
    "--path", $projectPath,
    "--log-file", $logFilePath,
    "--write-movie", $captureRequestPath,
    "--fixed-fps", [string]$Fps,
    "--quit-after", [string]$Frames,
    "--disable-vsync"
))

$projectUserArgs = [System.Collections.Generic.List[string]]::new()
if ($CreatorCapture) {
    $projectUserArgs.Add("--creator-capture")
}
foreach ($arg in $UserArgs) {
    if (-not [string]::IsNullOrWhiteSpace($arg)) {
        $projectUserArgs.Add($arg)
    }
}
if ($projectUserArgs.Count -gt 0) {
    $arguments.Add("--")
    foreach ($arg in $projectUserArgs) {
        $arguments.Add($arg)
    }
}

Write-Host "USING_GODOT_EXE=$resolvedGodotExe"
Write-Host "USING_GODOT_LOG_FILE=$logFilePath"
Write-Host "USING_CAPTURE_REQUEST=$captureRequestPath"

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

$framesWritten = Get-ChildItem -LiteralPath $OutputDir -Filter "$captureBaseName*.png" -File -ErrorAction SilentlyContinue |
    Sort-Object Name
$lastFrame = $framesWritten | Select-Object -Last 1
Write-Host "CAPTURE_FRAME_COUNT=$($framesWritten.Count)"
if ($lastFrame) {
    Write-Host "CAPTURE_LAST_FRAME=$($lastFrame.FullName)"
}

exit $exitCode
