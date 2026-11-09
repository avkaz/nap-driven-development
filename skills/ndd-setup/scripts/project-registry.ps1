<# Shared per-user project registry; no Python runtime required. #>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidateSet('Register', 'Cleanup')][string]$Action,
    [string]$Project, [string]$Prefix, [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
$stateDir = if ($env:NDD_STATE_DIR) { $env:NDD_STATE_DIR } else {
    Join-Path ([Environment]::GetFolderPath('UserProfile')) '.ndd'
}
$projectsDir = Join-Path $stateDir 'projects'
$lockDir = Join-Path $stateDir '.projects.lock'

function Assert-RealDirectoryPath([string]$Path) {
    if (-not [IO.Path]::IsPathRooted($Path) -or $Path -match '[\r\n\t]') { throw "Invalid directory path: $Path" }
    $current = [IO.Path]::GetFullPath($Path)
    if ($current.TrimEnd('\', '/') -eq [IO.Path]::GetPathRoot($current).TrimEnd('\', '/')) { throw 'A filesystem root cannot be the registry or Git directory.' }
    while ($current -and $current -ne [IO.Path]::GetPathRoot($current)) {
        $entry = Get-Item -LiteralPath $current -Force -ErrorAction SilentlyContinue
        if ($entry -and (-not $entry.PSIsContainer -or ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint))) {
            throw "Directory path is redirected or not a directory: $current"
        }
        $current = Split-Path $current -Parent
    }
}
function Invoke-GitText([string[]]$Arguments) {
    $lines = @(& git @Arguments)
    if ($LASTEXITCODE -ne 0) { throw "Git failed with exit code $LASTEXITCODE" }
    return $lines -join "`n"
}
function Get-RecordName([string]$Common) {
    $value = $Common
    if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) { $value = $value.ToLowerInvariant() }
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $digest = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($value)))).Replace('-', '').ToLowerInvariant()
        return Join-Path $projectsDir "$digest.record"
    } finally { $sha.Dispose() }
}
function Assert-GitDirectory([string]$Common) {
    Assert-RealDirectoryPath $Common
    $config = Get-Item -LiteralPath (Join-Path $Common 'config') -Force
    if ($config.PSIsContainer -or ($config.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Git config must be a regular file.' }
    $resolved = Invoke-GitText @("--git-dir=$Common", 'rev-parse', '--path-format=absolute', '--git-common-dir')
    if ([IO.Path]::GetFullPath($resolved) -ne [IO.Path]::GetFullPath($Common)) { throw 'Git directory changed.' }
}
function Get-SavedPrefix([string]$Common) {
    $values = @(& git config --file (Join-Path $Common 'config') --no-includes --get-all ndd.prefix)
    $code = $LASTEXITCODE
    if ($code -ne 0 -and $code -ne 1) { throw "Cannot read local ndd.prefix (exit=$code)." }
    return [PSCustomObject]@{ Present=($code -eq 0); Value=($values -join "`n") }
}
function Get-SpecsRoot([string]$Common) {
    $values = @(& git config --file (Join-Path $Common 'config') --no-includes --get ndd.specsRoot)
    $code = $LASTEXITCODE
    if ($code -eq 1) { return $null }
    if ($code -ne 0) { throw "Cannot read local ndd.specsRoot (exit=$code)." }
    return $values[0]
}
function Clear-PrivateSpecs([string]$Common) {
    $root = Get-SpecsRoot $Common
    if (-not $root) { return }
    $root = [IO.Path]::GetFullPath($root)
    $specsDir = [IO.Path]::GetFullPath((Join-Path $stateDir 'specs'))
    # Only a folder created by setup under the NDD state directory may be deleted.
    if ((Split-Path $root -Parent) -ne $specsDir) { throw "Private specs folder is not inside ${specsDir}: $root" }
    Assert-RealDirectoryPath $root
    Write-Host "Remove private specs settings (ndd.specsRoot, ndd-specs links, exclude line): $root"
    if ($DryRun) {
        if (Test-Path -LiteralPath $root) { Write-Host "Uninstall will ask whether to delete private specs: $root" }
        return
    }
    $worktrees = @(& git "--git-dir=$Common" worktree list --porcelain)
    if ($LASTEXITCODE -ne 0) { throw "Cannot list worktrees (exit=$LASTEXITCODE)." }
    foreach ($line in $worktrees) {
        if (-not $line.StartsWith('worktree ')) { continue }
        $link = Join-Path $line.Substring(9) 'ndd-specs'
        $entry = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
        if (-not $entry -or -not ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint)) { continue }
        $target = @($entry.Target)[0]
        # Non-recursive delete removes only the junction or link, never its target.
        if ($target -and [IO.Path]::GetFullPath($target) -eq $root) { [IO.Directory]::Delete($link) }
    }
    $exclude = Join-Path $Common 'info/exclude'
    if (Test-Path -LiteralPath $exclude -PathType Leaf) {
        $lines = [IO.File]::ReadAllLines($exclude)
        $kept = @($lines | Where-Object { $_ -cne '/ndd-specs' })
        if ($kept.Count -ne $lines.Count) { [IO.File]::WriteAllLines($exclude, [string[]]$kept) }
    }
    if (Test-Path -LiteralPath $root -PathType Container) {
        Write-Host "Delete private specs permanently? $root [y/N] " -NoNewline
        $answer = [Console]::In.ReadLine()
        if ($answer -eq 'y') {
            [IO.Directory]::Delete($root, $true)
            Write-Host "Deleted private specs: $root"
        } else {
            Write-Host "Kept private specs: $root"
        }
    }
    $null = Invoke-GitText @('config', '--file', (Join-Path $Common 'config'), '--no-includes', '--unset-all', 'ndd.specsRoot')
}
function Read-Record([string]$Path) {
    $entry = Get-Item -LiteralPath $Path -Force
    if ($entry.PSIsContainer -or ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "Invalid record: $Path" }
    $lines = [IO.File]::ReadAllLines($Path, [Text.Encoding]::UTF8)
    if ($lines.Count -ne 5 -or $lines[0] -cne 'ndd-project-v1' -or $lines[3] -cne 'ndd.prefix' -or $lines[4] -cnotmatch '^[a-z][a-z0-9]{1,15}$') {
        throw "Malformed record: $Path"
    }
    if ($Path -ne (Get-RecordName $lines[2])) { throw "Record identity mismatch: $Path" }
    return [PSCustomObject]@{ Project=$lines[1]; Common=$lines[2]; Prefix=$lines[4] }
}

Assert-RealDirectoryPath $stateDir
Assert-RealDirectoryPath $projectsDir
if (Get-Item -LiteralPath $lockDir -Force -ErrorAction SilentlyContinue) { throw "Registry lock exists: $lockDir" }
if ($Action -eq 'Cleanup' -and -not (Test-Path -LiteralPath $projectsDir)) { return }
foreach ($variable in @('GIT_DIR', 'GIT_WORK_TREE', 'GIT_COMMON_DIR', 'GIT_CONFIG', 'GIT_CONFIG_COUNT')) {
    if ([Environment]::GetEnvironmentVariable($variable)) { throw "Run without the $variable environment override." }
}
if ($Action -eq 'Register' -and $DryRun) { throw 'Registration does not accept -DryRun.' }
$locked = $false
$temporary = $null
try {
    if (-not $DryRun) {
        $null = New-Item -ItemType Directory -Force -Path $stateDir
        # No -Force: an existing directory lock belongs to another operation.
        $null = New-Item -ItemType Directory -Path $lockDir
        $locked = $true
    }
    if ($Action -eq 'Register') {
        if (-not $Project -or $Prefix -cnotmatch '^[a-z][a-z0-9]{1,15}$') { throw 'Provide a project and a valid prefix.' }
        $projectRoot = Invoke-GitText @('-C', $Project, 'rev-parse', '--show-toplevel')
        $common = Invoke-GitText @('-C', $projectRoot, 'rev-parse', '--path-format=absolute', '--git-common-dir')
        $projectRoot = [IO.Path]::GetFullPath($projectRoot)
        $common = [IO.Path]::GetFullPath($common)
        Assert-RealDirectoryPath $projectRoot
        Assert-GitDirectory $common
        $saved = Get-SavedPrefix $common
        if (-not $saved.Present -or $saved.Value -cne $Prefix) { throw 'Save and verify the confirmed local prefix before registering it.' }
        $null = New-Item -ItemType Directory -Force -Path $projectsDir
        $record = Get-RecordName $common
        if (Get-Item -LiteralPath $record -Force -ErrorAction SilentlyContinue) {
            $existing = Read-Record $record
            if ($existing.Common -eq $common -and $existing.Prefix -ceq $Prefix) {
                Write-Host "Project already registered: $projectRoot"
                return
            }
        }
        $temporary = Join-Path $projectsDir ('.record.' + [Guid]::NewGuid().ToString('N'))
        $text = "ndd-project-v1`n$projectRoot`n$common`nndd.prefix`n$Prefix`n"
        [IO.File]::WriteAllText($temporary, $text, (New-Object Text.UTF8Encoding($false)))
        if (Test-Path -LiteralPath $record) { [IO.File]::Replace($temporary, $record, [NullString]::Value) }
        else { [IO.File]::Move($temporary, $record) }
        $temporary = $null
        Write-Host "Registered project: $projectRoot (ndd.prefix=$Prefix)"
        return
    }
    $failed = $false
    foreach ($entry in Get-ChildItem -LiteralPath $projectsDir -Force) {
        try {
            $record = Read-Record $entry.FullName
            Assert-GitDirectory $record.Common
            Clear-PrivateSpecs $record.Common
            $saved = Get-SavedPrefix $record.Common
            if ($saved.Present -and $saved.Value -cne $record.Prefix) { throw "Prefix changed: $($record.Project)" }
            Write-Host "Remove registered ndd.prefix=$($record.Prefix): $($record.Project)"
            if ($DryRun) { continue }
            if ($saved.Present) {
                $null = Invoke-GitText @('config', '--file', (Join-Path $record.Common 'config'), '--no-includes', '--unset-all', 'ndd.prefix', "^$($record.Prefix)$")
                if ((Get-SavedPrefix $record.Common).Present) { throw 'Prefix changed during cleanup.' }
            }
            [IO.File]::Delete($entry.FullName)
        } catch {
            $failed = $true
            Write-Warning "Project cleanup skipped; retained record $($entry.FullName): $_"
        }
    }
    if (-not $DryRun -and -not $failed) {
        [IO.Directory]::Delete($projectsDir)
        $specsDir = Join-Path $stateDir 'specs'
        if ((Test-Path -LiteralPath $specsDir) -and [IO.Directory]::GetFileSystemEntries($specsDir).Count -eq 0) {
            [IO.Directory]::Delete($specsDir)
        }
    }
} finally {
    if ($temporary) { [IO.File]::Delete($temporary) }
    if ($locked) { [IO.Directory]::Delete($lockDir) }
}
if (-not $DryRun -and [IO.Directory]::GetFileSystemEntries($stateDir).Count -eq 0) {
    [IO.Directory]::Delete($stateDir)
}
