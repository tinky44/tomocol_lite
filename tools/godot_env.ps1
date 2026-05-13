function Get-TomocolRepoRoot {
    param(
        [string]$ScriptRoot
    )

    $configuredRoot = [Environment]::GetEnvironmentVariable("TOMOCOL_REPO_ROOT")
    if (-not [string]::IsNullOrWhiteSpace($configuredRoot)) {
        return Resolve-TomocolPath -PathValue $configuredRoot -BasePath (Get-Location)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $ScriptRoot ".."))
}

function Get-TomocolEnvValue {
    param(
        [string]$Name,
        [string]$DefaultValue = ""
    )

    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $DefaultValue
    }

    return [Environment]::ExpandEnvironmentVariables($value)
}

function Import-TomocolDotEnv {
    param(
        [string]$RepoRoot
    )

    $envPath = Join-Path $RepoRoot ".env"
    if (-not (Test-Path -LiteralPath $envPath)) {
        return
    }

    foreach ($line in Get-Content -LiteralPath $envPath) {
        $trimmedLine = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmedLine) -or $trimmedLine.StartsWith("#")) {
            continue
        }

        $separatorIndex = $trimmedLine.IndexOf("=")
        if ($separatorIndex -le 0) {
            continue
        }

        $name = $trimmedLine.Substring(0, $separatorIndex).Trim()
        $value = $trimmedLine.Substring($separatorIndex + 1).Trim()
        if ([string]::IsNullOrWhiteSpace($name) -or $name.StartsWith("#")) {
            continue
        }

        if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        # Shell/process env wins over .env. This keeps CI and one-off command overrides predictable.
        if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))) {
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
}

function Resolve-TomocolPath {
    param(
        [string]$PathValue,
        [string]$BasePath
    )

    $expandedPath = [Environment]::ExpandEnvironmentVariables($PathValue)
    if ([System.IO.Path]::IsPathRooted($expandedPath)) {
        return [System.IO.Path]::GetFullPath($expandedPath)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $BasePath $expandedPath))
}

function Get-TomocolPathSetting {
    param(
        [string]$Name,
        [string]$DefaultRelativePath,
        [string]$RepoRoot
    )

    $value = Get-TomocolEnvValue -Name $Name -DefaultValue $DefaultRelativePath
    return Resolve-TomocolPath -PathValue $value -BasePath $RepoRoot
}

function Format-TomocolDisplayPath {
    param(
        [string]$PathValue,
        [string]$RepoRoot
    )

    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        return ""
    }

    $fullPath = [System.IO.Path]::GetFullPath($PathValue)
    $repoFullPath = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $repoPrefix = $repoFullPath + [System.IO.Path]::DirectorySeparatorChar
    if ($fullPath.StartsWith($repoPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relativePath = $fullPath.Substring($repoPrefix.Length)
        return ".\" + $relativePath
    }

    $userProfile = [Environment]::GetEnvironmentVariable("USERPROFILE")
    if ([string]::IsNullOrWhiteSpace($userProfile)) {
        $userProfile = [Environment]::GetFolderPath("UserProfile")
    }
    if (-not [string]::IsNullOrWhiteSpace($userProfile)) {
        $userProfile = [System.IO.Path]::GetFullPath($userProfile).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
        $userPrefix = $userProfile + [System.IO.Path]::DirectorySeparatorChar
        if ($fullPath.StartsWith($userPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            $relativePath = $fullPath.Substring($userPrefix.Length)
            return "`$env:USERPROFILE\" + $relativePath
        }
    }

    return $fullPath
}

function Format-TomocolOutputLine {
    param(
        [object]$Line,
        [string]$RepoRoot
    )

    $text = [string]$Line
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $text
    }

    $repoFullPath = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $text = $text.Replace($repoFullPath, ".")

    $userProfile = [Environment]::GetEnvironmentVariable("USERPROFILE")
    if ([string]::IsNullOrWhiteSpace($userProfile)) {
        $userProfile = [Environment]::GetFolderPath("UserProfile")
    }
    if (-not [string]::IsNullOrWhiteSpace($userProfile)) {
        $userProfile = [System.IO.Path]::GetFullPath($userProfile).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
        $text = $text.Replace($userProfile, "`$env:USERPROFILE")
    }

    return $text
}

function Resolve-GodotExeCandidate {
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

function Get-GodotSearchRoots {
    param(
        [string]$RepoRoot
    )

    $configuredRoots = Get-TomocolEnvValue -Name "TOMOCOL_GODOT_SEARCH_ROOTS"
    if (-not [string]::IsNullOrWhiteSpace($configuredRoots)) {
        $roots = @()
        foreach ($rawRoot in $configuredRoots -split [System.IO.Path]::PathSeparator) {
            if (-not [string]::IsNullOrWhiteSpace($rawRoot)) {
                $roots += Resolve-TomocolPath -PathValue $rawRoot -BasePath $RepoRoot
            }
        }
        return $roots | Select-Object -Unique
    }

    $defaultRoots = @()
    $userProfile = [Environment]::GetEnvironmentVariable("USERPROFILE")
    if ([string]::IsNullOrWhiteSpace($userProfile)) {
        $userProfile = [Environment]::GetFolderPath("UserProfile")
    }
    if (-not [string]::IsNullOrWhiteSpace($userProfile)) {
        $defaultRoots += (Join-Path $userProfile "Downloads")
        $defaultRoots += (Join-Path $userProfile "Desktop")
    }

    $programFiles = [Environment]::GetEnvironmentVariable("ProgramFiles")
    if (-not [string]::IsNullOrWhiteSpace($programFiles)) {
        $defaultRoots += $programFiles
    }

    $programFilesX86 = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)")
    if (-not [string]::IsNullOrWhiteSpace($programFilesX86)) {
        $defaultRoots += $programFilesX86
    }

    return $defaultRoots | Select-Object -Unique
}

function Resolve-GodotExe {
    param(
        [string]$PreferredPath,
        [string]$RepoRoot
    )

    $candidates = @()

    if (-not [string]::IsNullOrWhiteSpace($PreferredPath)) {
        $candidates += Resolve-TomocolPath -PathValue $PreferredPath -BasePath $RepoRoot
    }

    $tomocolGodotExe = Get-TomocolEnvValue -Name "TOMOCOL_GODOT_EXE"
    if (-not [string]::IsNullOrWhiteSpace($tomocolGodotExe)) {
        $candidates += Resolve-TomocolPath -PathValue $tomocolGodotExe -BasePath $RepoRoot
    }

    $godotExe = Get-TomocolEnvValue -Name "GODOT_EXE"
    if (-not [string]::IsNullOrWhiteSpace($godotExe)) {
        $candidates += Resolve-TomocolPath -PathValue $godotExe -BasePath $RepoRoot
    }

    foreach ($root in Get-GodotSearchRoots -RepoRoot $RepoRoot) {
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
        $resolvedCandidate = Resolve-GodotExeCandidate -CandidatePath $candidate
        if (-not [string]::IsNullOrWhiteSpace($resolvedCandidate)) {
            return $resolvedCandidate
        }
    }

    throw "Godot executable was not found. Set -GodotExe, TOMOCOL_GODOT_EXE, or GODOT_EXE."
}

function Set-GodotRuntimeEnvironment {
    param(
        [string]$RuntimeRoot
    )

    $runtimeEnv = @{
        "APPDATA" = Join-Path $RuntimeRoot "AppData\Roaming"
        "LOCALAPPDATA" = Join-Path $RuntimeRoot "AppData\Local"
        "TEMP" = Join-Path $RuntimeRoot "Temp"
        "TMP" = Join-Path $RuntimeRoot "Temp"
    }

    foreach ($path in $runtimeEnv.Values) {
        New-Item -ItemType Directory -Force -Path $path | Out-Null
    }

    foreach ($key in $runtimeEnv.Keys) {
        Set-Item -Path "Env:$key" -Value $runtimeEnv[$key]
    }
}

function Restore-Environment {
    param(
        [hashtable]$OriginalEnv
    )

    foreach ($key in $OriginalEnv.Keys) {
        if ($null -eq $OriginalEnv[$key]) {
            Remove-Item -Path "Env:$key" -ErrorAction SilentlyContinue
        }
        else {
            Set-Item -Path "Env:$key" -Value $OriginalEnv[$key]
        }
    }
}
