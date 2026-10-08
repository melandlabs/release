<#
.SYNOPSIS
  Install the published Alloomi NSIS installer on Windows and verify the app
  actually starts.

.DESCRIPTION
  Intended to run on the real Windows 11 runner (windows-11-arm). The published
  installer is x64, so the app is exercised through the Windows 11 x64
  emulation layer -- noticeably slower, but it is genuine Windows 11.

  Checks, in order:
    1. the NSIS installer completes silently and drops Alloomi.exe + its
       uninstaller on disk, together with the packaged web server
    2. the process stays alive and creates a real top-level window
    3. WebView2 spins up, i.e. the frontend came up rather than an empty frame

  Diagnostics and a screenshot are captured even when a check fails, so the
  artifact upload always has something to show.

.EXAMPLE
  ./smoke.ps1 -InstallerPath C:\ci\installer\Alloomi_0.5.2_windows_amd64.exe
#>
param(
    # Absolute path to the downloaded *_windows_amd64.exe NSIS installer.
    [Parameter(Mandatory = $true)]
    [string]$InstallerPath,

    # x64 emulation makes first launch crawl; this needs to be generous.
    [int]$LaunchTimeoutSeconds = 300,

    # Screenshot output directory, resolved against the working directory.
    [string]$ArtifactDir = 'smoke-artifacts'
)

$ErrorActionPreference = 'Stop'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        throw "SMOKE FAILED: $Message"
    }
}

function Test-WebViewChild {
    param([int]$ParentPid)
    # Win32_Process is the only way to learn the parent PID of a process that is
    # already running. SilentlyContinue keeps a transient WMI hiccup from
    # failing the test -- the caller just polls again.
    @(Get-CimInstance Win32_Process -Filter "Name='msedgewebview2.exe'" -ErrorAction SilentlyContinue |
            Where-Object { $_.ParentProcessId -eq $ParentPid }).Count -gt 0
}

New-Item -ItemType Directory -Force -Path $ArtifactDir | Out-Null
$ArtifactDir = (Resolve-Path $ArtifactDir).Path
$app = $null

try {
    # ── 1. Silent install ──────────────────────────────────────────────────────
    # SmartScreen trips on freshly downloaded .exe files even on CI runners, and
    # nothing in this test is interactive anyway.
    Unblock-File -Path $InstallerPath -ErrorAction SilentlyContinue

    Write-Host '::group::Silent install'
    $installer = Get-Item $InstallerPath
    Write-Host ('{0} ({1} MB)' -f $installer.Name, [math]::Round($installer.Length / 1MB, 1))

    # -Wait guarantees the installer has exited, so reading ExitCode here is safe.
    $install = Start-Process -FilePath $installer.FullName -ArgumentList '/S' -PassThru -Wait
    Assert-True ($install.ExitCode -eq 0) "installer exited with code $($install.ExitCode)"
    Write-Host '::endgroup::'

    # Tauri's default NSIS installMode is currentUser, so the uninstall entry
    # belongs under HKCU. Tauri's installer is a 32-bit stub, and WOW64
    # redirection puts its writes in the 32-bit view of HKCU, so that view has
    # to be searched too. This is only used to locate the install dir -- the
    # file assertions below are what actually prove the install worked.
    Write-Host '::group::Installed layout'
    $entry = Get-ItemProperty `
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' `
        -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like '*Alloomi*' } |
        Select-Object -First 1

    if ($entry) {
        Write-Host "uninstall entry: $($entry.UninstallString)"
    } else {
        Write-Host '::warning::no Alloomi uninstall entry found; falling back to path discovery'
    }

    $candidateRoots = @($entry.InstallLocation, "$env:LOCALAPPDATA\Alloomi", "$env:ProgramFiles\Alloomi") |
        Where-Object { $_ }
    $appExe = $candidateRoots |
        ForEach-Object { Join-Path $_ 'Alloomi.exe' } |
        Where-Object { Test-Path $_ } |
        Select-Object -First 1

    if (-not $appExe) {
        $appExe = (Get-ChildItem -Path $env:LOCALAPPDATA -Filter 'Alloomi.exe' -Recurse -Depth 3 `
                -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
    }
    Assert-True ($appExe) 'Alloomi.exe not found after the installer finished'

    $installRoot = Split-Path $appExe
    Write-Host "installed: $appExe"
    Write-Host ('version:   {0}' -f (Get-Item $appExe).VersionInfo.ProductVersion)

    $uninstaller = Get-ChildItem $installRoot -Filter 'uninstall.exe' -ErrorAction SilentlyContinue |
        Select-Object -First 1
    Assert-True ($null -ne $uninstaller) 'no uninstall.exe next to Alloomi.exe -- the NSIS install did not finish'

    # The web UI is served from the Next.js standalone bundle that ships as a
    # Tauri resource. A missing server.js is the class of packaging bug that is
    # invisible until the app is installed and launched (see the v0.6.6
    # imessage-kit regression), so check for it rather than trusting the build.
    $serverBundle = Get-ChildItem $installRoot -Filter 'server.js' -File -Recurse -Depth 5 -ErrorAction SilentlyContinue |
        Select-Object -First 1
    Assert-True ($null -ne $serverBundle) "no packaged server.js under $installRoot -- the web bundle is missing from the installer"

    Write-Host ('web server: {0}' -f $serverBundle.FullName)
    Write-Host ('size:       {0} MB' -f [math]::Round((Get-ChildItem $installRoot -Recurse -File -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum / 1MB, 1))
    Write-Host '::endgroup::'

    # ── 2. Launch ──────────────────────────────────────────────────────────────
    Write-Host '::group::Launch'
    # A previous installer run may have left the app up; kill it so the PID
    # polled below is definitely the one this test started. Stop-Process is
    # asynchronous, so give the old process a moment to release its exe.
    Get-Process -Name 'Alloomi' -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3

    $app = Start-Process -FilePath $appExe -PassThru
    Write-Host "started Alloomi.exe (pid $($app.Id))"

    $deadline = (Get-Date).AddSeconds($LaunchTimeoutSeconds)
    $windowReady = $false
    while ((Get-Date) -lt $deadline) {
        # Process.ExitCode throws until the process has actually exited, so it
        # must only ever be read in here -- never as an Assert-True argument,
        # which PowerShell evaluates eagerly on every poll.
        if ($app.HasExited) {
            throw "SMOKE FAILED: Alloomi.exe exited early with code $($app.ExitCode)"
        }

        $app.Refresh()
        if ($app.MainWindowHandle -ne 0) { $windowReady = $true; break }
        Start-Sleep -Seconds 5
    }
    Assert-True $windowReady "no main window after $LaunchTimeoutSeconds seconds"

    $app.Refresh()
    Write-Host "main window: '$($app.MainWindowTitle)' (hwnd $($app.MainWindowHandle))"

    # WebView2 renders the UI, so its child process is the real proof that the
    # frontend booted instead of the app showing an empty frame. Only worth
    # querying once the window exists -- Win32_Process is an expensive WMI class
    # and there is no point polling it 60 times under x64 emulation.
    $webviewReady = $false
    while ((Get-Date) -lt $deadline) {
        if (Test-WebViewChild -ParentPid $app.Id) { $webviewReady = $true; break }
        Start-Sleep -Seconds 5
    }
    Assert-True $webviewReady "no msedgewebview2.exe child process after $LaunchTimeoutSeconds seconds"
    Write-Host '::endgroup::'
}
finally {
    Write-Host '::group::Diagnostics'

    if ($app) {
        $app.Refresh()
        Write-Host ('app running:  {0}' -f (-not $app.HasExited))
        if ($app.HasExited) {
            Write-Host ('app exit code: {0}' -f $app.ExitCode)
        } else {
            Write-Host ('app window:   "{0}" (hwnd {1})' -f $app.MainWindowTitle, $app.MainWindowHandle)
            Write-Host 'child processes:'
            # SilentlyContinue everywhere in here: an exception thrown from a
            # finally block replaces the real failure and hides the reason.
            Get-CimInstance Win32_Process -Filter "ParentProcessId=$($app.Id)" -ErrorAction SilentlyContinue |
                Select-Object ProcessId, Name | Format-Table -AutoSize | Out-String | Write-Host
        }
    }

    # The WebView2 runtime is the most common reason a Tauri window never
    # appears, so record whether it was there at all.
    $webviewRuntime = Get-ItemProperty `
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}',
        'HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}' `
        -ErrorAction SilentlyContinue | Select-Object -First 1
    $runtimeVersion = if ($webviewRuntime) { $webviewRuntime.pv } else { 'NOT FOUND' }
    Write-Host "webview2 runtime: $runtimeVersion"

    Write-Host 'recently written app data:'
    Get-ChildItem $env:APPDATA, $env:LOCALAPPDATA -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-30) } |
        Select-Object FullName, LastWriteTime | Format-Table -AutoSize | Out-String | Write-Host

    if (-not $app -or $app.HasExited) {
        Write-Host '::warning::Alloomi is not running; no screenshot captured'
    } else {
        # Let the frontend paint first -- this is the only place a delay helps,
        # because the failure paths never reach the end of the try block.
        Start-Sleep -Seconds 15

        # Best effort: CI runners have no attached desktop, so this usually
        # produces a black image or fails outright. Never fail the run on it.
        try {
            Add-Type -AssemblyName System.Windows.Forms
            Add-Type -AssemblyName System.Drawing
            $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
            $bitmap = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            $graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
            $shot = Join-Path $ArtifactDir 'alloomi-desktop.png'
            $bitmap.Save($shot, [System.Drawing.Imaging.ImageFormat]::Png)
            $graphics.Dispose()
            $bitmap.Dispose()
            Write-Host "screenshot: $shot"
        } catch {
            Write-Host "::warning::screenshot capture failed: $($_.Exception.Message)"
        }
    }
    Write-Host '::endgroup::'
}
