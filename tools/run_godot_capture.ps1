param(
    [string]$GodotExe = "",
    [string]$OutputDir = "",
    [string]$Prefix = "capture",
    [int]$Frames = 12,
    [int]$Fps = 10,
    [switch]$CreatorCapture,
    [string[]]$UserArgs = @()
)

. (Join-Path $PSScriptRoot "godot_env.ps1")

if ($Frames -lt 1) {
    throw "-Frames must be 1 or greater."
}

if ($Fps -lt 1) {
    throw "-Fps must be 1 or greater."
}

$repoRoot = Get-TomocolRepoRoot -ScriptRoot $PSScriptRoot
Import-TomocolDotEnv -RepoRoot $repoRoot
$projectPath = Get-TomocolPathSetting -Name "TOMOCOL_GODOT_PROJECT_PATH" -DefaultRelativePath "godot-project" -RepoRoot $repoRoot
$runtimeRoot = Get-TomocolPathSetting -Name "TOMOCOL_GODOT_RUNTIME_ROOT" -DefaultRelativePath "artifacts\godot-runtime" -RepoRoot $repoRoot
$godotLogDir = Join-Path $runtimeRoot "logs"

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Get-TomocolPathSetting -Name "TOMOCOL_CAPTURE_OUTPUT_DIR" -DefaultRelativePath "screen_shots" -RepoRoot $repoRoot
}
else {
    $OutputDir = Resolve-TomocolPath -PathValue $OutputDir -BasePath $repoRoot
}

$resolvedGodotExe = Resolve-GodotExe -PreferredPath $GodotExe -RepoRoot $repoRoot
$safePrefix = ($Prefix -replace '[<>:"/\\|?*]', '_')
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$captureBaseName = "$safePrefix`_$timestamp"
$captureRequestPath = Join-Path $OutputDir "$captureBaseName.png"
$logFilePath = Join-Path $godotLogDir "$captureBaseName.log"

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
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

Write-Host "USING_GODOT_EXE=$(Format-TomocolDisplayPath -PathValue $resolvedGodotExe -RepoRoot $repoRoot)"
Write-Host "USING_GODOT_PROJECT_PATH=$(Format-TomocolDisplayPath -PathValue $projectPath -RepoRoot $repoRoot)"
Write-Host "USING_GODOT_RUNTIME_ROOT=$(Format-TomocolDisplayPath -PathValue $runtimeRoot -RepoRoot $repoRoot)"
Write-Host "USING_GODOT_LOG_FILE=$(Format-TomocolDisplayPath -PathValue $logFilePath -RepoRoot $repoRoot)"
Write-Host "USING_CAPTURE_REQUEST=$(Format-TomocolDisplayPath -PathValue $captureRequestPath -RepoRoot $repoRoot)"

$originalEnv = @{
    "APPDATA" = $env:APPDATA
    "LOCALAPPDATA" = $env:LOCALAPPDATA
    "TEMP" = $env:TEMP
    "TMP" = $env:TMP
}

$exitCode = 1
try {
    Set-GodotRuntimeEnvironment -RuntimeRoot $runtimeRoot
    $godotOutput = & $resolvedGodotExe @arguments 2>&1
    $exitCode = $LASTEXITCODE
    foreach ($line in $godotOutput) {
        Write-Host (Format-TomocolOutputLine -Line $line -RepoRoot $repoRoot)
    }
}
finally {
    Restore-Environment -OriginalEnv $originalEnv
}

$framesWritten = Get-ChildItem -LiteralPath $OutputDir -Filter "$captureBaseName*.png" -File -ErrorAction SilentlyContinue |
    Sort-Object Name
$lastFrame = $framesWritten | Select-Object -Last 1
Write-Host "CAPTURE_FRAME_COUNT=$($framesWritten.Count)"
if ($lastFrame) {
    Write-Host "CAPTURE_LAST_FRAME=$(Format-TomocolDisplayPath -PathValue $lastFrame.FullName -RepoRoot $repoRoot)"
}

exit $exitCode
