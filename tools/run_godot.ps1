param(
    [string]$GodotExe = "",
    [switch]$Headless,
    [switch]$Quit,
    [string]$LogPrefix = "godot"
)

. (Join-Path $PSScriptRoot "godot_env.ps1")

$repoRoot = Get-TomocolRepoRoot -ScriptRoot $PSScriptRoot
Import-TomocolDotEnv -RepoRoot $repoRoot
$projectPath = Get-TomocolPathSetting -Name "TOMOCOL_GODOT_PROJECT_PATH" -DefaultRelativePath "godot-project" -RepoRoot $repoRoot
$runtimeRoot = Get-TomocolPathSetting -Name "TOMOCOL_GODOT_RUNTIME_ROOT" -DefaultRelativePath "artifacts\godot-runtime" -RepoRoot $repoRoot
$godotLogDir = Join-Path $runtimeRoot "logs"

$resolvedGodotExe = Resolve-GodotExe -PreferredPath $GodotExe -RepoRoot $repoRoot
$safeLogPrefix = ($LogPrefix -replace '[<>:"/\\|?*]', '_')
$logTimestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFilePath = Join-Path $godotLogDir "$safeLogPrefix`_$logTimestamp.log"

New-Item -ItemType Directory -Force -Path $godotLogDir | Out-Null

Write-Host "USING_GODOT_EXE=$(Format-TomocolDisplayPath -PathValue $resolvedGodotExe -RepoRoot $repoRoot)"
Write-Host "USING_GODOT_PROJECT_PATH=$(Format-TomocolDisplayPath -PathValue $projectPath -RepoRoot $repoRoot)"
Write-Host "USING_GODOT_RUNTIME_ROOT=$(Format-TomocolDisplayPath -PathValue $runtimeRoot -RepoRoot $repoRoot)"
Write-Host "USING_GODOT_LOG_FILE=$(Format-TomocolDisplayPath -PathValue $logFilePath -RepoRoot $repoRoot)"

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

exit $exitCode
