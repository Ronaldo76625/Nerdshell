param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceRoot
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$Host.UI.RawUI.WindowTitle = "Nerdshell Windows Installer"

function Write-Step([string]$Message) {
    Write-Host "`n[Nerdshell] $Message" -ForegroundColor Cyan
}

function Write-WarningMessage([string]$Message) {
    Write-Host "[Nerdshell] $Message" -ForegroundColor Yellow
}

function Backup-Item([string]$Path, [string]$BackupRoot) {
    if (Test-Path -LiteralPath $Path) {
        $safeName = ($Path -replace '[:\\/]', '_').Trim('_')
        Copy-Item -LiteralPath $Path -Destination (Join-Path $BackupRoot $safeName) -Recurse -Force
    }
}

function Install-WinGetPackage {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$Name,
        [switch]$Required
    )

    & winget list --id $Id --exact --accept-source-agreements *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ $Name ya está instalado" -ForegroundColor Green
        return $true
    }

    Write-Host "  → Instalando $Name..."
    & winget install --id $Id --exact --source winget `
        --accept-package-agreements --accept-source-agreements `
        --silent --disable-interactivity

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ $Name instalado" -ForegroundColor Green
        return $true
    }

    if ($Required) {
        Write-Host "  ✗ No se pudo instalar $Name" -ForegroundColor Red
    } else {
        Write-WarningMessage "No se pudo instalar la herramienta opcional $Name."
    }
    return $false
}

function Install-NerdFont {
    $fontRegistry = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    $existing = Get-ItemProperty -Path $fontRegistry -ErrorAction SilentlyContinue
    if ($existing.PSObject.Properties.Name -match "JetBrainsMono.*Nerd") {
        Write-Host "  ✓ JetBrainsMono Nerd Font ya está instalada" -ForegroundColor Green
        return
    }

    Write-Host "  → Descargando JetBrainsMono Nerd Font..."
    $fontWork = Join-Path $env:TEMP "NerdshellFonts"
    $fontZip = Join-Path $fontWork "JetBrainsMono.zip"
    $fontExtract = Join-Path $fontWork "JetBrainsMono"
    Remove-Item -LiteralPath $fontWork -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $fontWork -Force | Out-Null

    Invoke-WebRequest `
        -Uri "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" `
        -OutFile $fontZip -UseBasicParsing
    Expand-Archive -LiteralPath $fontZip -DestinationPath $fontExtract -Force

    $fonts = Get-ChildItem -Path $fontExtract -Filter "JetBrainsMonoNerdFontMono-*.ttf" -Recurse
    if (-not $fonts) {
        throw "No se encontraron fuentes JetBrainsMono Nerd Font dentro del archivo descargado."
    }

    foreach ($font in $fonts) {
        $target = Join-Path $env:WINDIR "Fonts\$($font.Name)"
        Copy-Item -LiteralPath $font.FullName -Destination $target -Force
        $displayName = "$($font.BaseName) (TrueType)"
        New-ItemProperty -Path $fontRegistry -Name $displayName -Value $font.Name -PropertyType String -Force | Out-Null
    }
    Write-Host "  ✓ JetBrainsMono Nerd Font instalada" -ForegroundColor Green
}

function Refresh-ProcessPath {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
}

function Configure-PowerShellProfile([string]$BackupRoot) {
    $documents = [Environment]::GetFolderPath("MyDocuments")
    $profileDirectory = Join-Path $documents "PowerShell"
    $profilePath = Join-Path $profileDirectory "Microsoft.PowerShell_profile.ps1"
    New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null
    Backup-Item $profilePath $BackupRoot
    Copy-Item -LiteralPath (Join-Path $ResourceRoot "Microsoft.PowerShell_profile.ps1") -Destination $profilePath -Force

    $configDirectory = Join-Path $HOME ".config"
    $starshipPath = Join-Path $configDirectory "starship.toml"
    New-Item -ItemType Directory -Path $configDirectory -Force | Out-Null
    Backup-Item $starshipPath $BackupRoot
    Copy-Item -LiteralPath (Join-Path $ResourceRoot "starship.toml") -Destination $starshipPath -Force

    Write-Host "  ✓ Perfil PowerShell y Starship configurados" -ForegroundColor Green
}

function Configure-GitDelta {
    $delta = Get-Command delta -ErrorAction SilentlyContinue
    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $delta -or -not $git) {
        Write-WarningMessage "Git Delta no está disponible; se conserva el pager actual de Git."
        return
    }

    git config --global core.pager "delta"
    git config --global interactive.diffFilter "delta --color-only"
    git config --global delta.navigate true
    git config --global delta.side-by-side true
    git config --global delta.line-numbers true
    git config --global merge.conflictstyle zdiff3
    git config --global diff.colorMoved default
    Write-Host "  ✓ Git Delta configurado" -ForegroundColor Green
}

function Configure-WindowsTerminal([string]$BackupRoot) {
    $profileGuid = "{45f7063e-6f80-4fe9-a38c-9e345fb2c86c}"
    $fragmentDirectory = Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal\Fragments\Nerdshell"
    $fragmentPath = Join-Path $fragmentDirectory "Nerdshell.json"
    New-Item -ItemType Directory -Path $fragmentDirectory -Force | Out-Null
    Backup-Item $fragmentPath $BackupRoot

    $fragment = @'
{
  "profiles": [
    {
      "guid": "{45f7063e-6f80-4fe9-a38c-9e345fb2c86c}",
      "name": "Nerdshell",
      "commandline": "pwsh.exe -NoLogo",
      "startingDirectory": "%USERPROFILE%",
      "colorScheme": "Nerdshell",
      "font": {
        "face": "JetBrainsMono Nerd Font Mono",
        "size": 11
      },
      "cursorShape": "filledBox",
      "historySize": 100000,
      "opacity": 96,
      "padding": "12",
      "useAcrylic": true
    }
  ],
  "schemes": [
    {
      "name": "Nerdshell",
      "background": "#0A0E16",
      "foreground": "#C0CAF5",
      "black": "#15161E",
      "red": "#F7768E",
      "green": "#9ECE6A",
      "yellow": "#E0AF68",
      "blue": "#7AA2F7",
      "purple": "#BB9AF7",
      "cyan": "#7DCFFF",
      "white": "#A9B1D6",
      "brightBlack": "#414868",
      "brightRed": "#F7768E",
      "brightGreen": "#9ECE6A",
      "brightYellow": "#E0AF68",
      "brightBlue": "#7AA2F7",
      "brightPurple": "#BB9AF7",
      "brightCyan": "#7DCFFF",
      "brightWhite": "#C0CAF5",
      "cursorColor": "#9ECE6A",
      "selectionBackground": "#33467C"
    }
  ]
}
'@
    $fragment | Out-File -LiteralPath $fragmentPath -Encoding utf8 -Force

    $terminalPackage = Get-ChildItem -Path (Join-Path $env:LOCALAPPDATA "Packages") `
        -Directory -Filter "Microsoft.WindowsTerminal_*" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($terminalPackage) {
        $settingsDirectory = Join-Path $terminalPackage.FullName "LocalState"
    } else {
        $settingsDirectory = Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal"
    }
    $settingsPath = Join-Path $settingsDirectory "settings.json"
    New-Item -ItemType Directory -Path $settingsDirectory -Force | Out-Null
    Backup-Item $settingsPath $BackupRoot

    if (Test-Path -LiteralPath $settingsPath) {
        $settings = Get-Content -LiteralPath $settingsPath -Raw
        if ($settings -match '"defaultProfile"\s*:') {
            $settings = [regex]::Replace(
                $settings,
                '"defaultProfile"\s*:\s*"[^"]*"',
                '"defaultProfile": "' + $profileGuid + '"',
                1
            )
        } else {
            $settings = [regex]::Replace(
                $settings,
                '^\s*\{',
                "{`r`n    `"defaultProfile`": `"$profileGuid`",",
                1
            )
        }
    } else {
        $settings = @"
{
    `"`$schema`": `"https://aka.ms/terminal-profiles-schema`",
    `"defaultProfile`": `"$profileGuid`",
    `"profiles`": { `"defaults`": {}, `"list`": [] }
}
"@
    }
    $settings | Out-File -LiteralPath $settingsPath -Encoding utf8 -Force

    $wt = Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps\wt.exe"
    if (Test-Path -LiteralPath $wt) {
        $shell = New-Object -ComObject WScript.Shell
        $desktopShortcut = Join-Path ([Environment]::GetFolderPath("Desktop")) "Nerdshell Terminal.lnk"
        $startMenuDirectory = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Nerdshell"
        New-Item -ItemType Directory -Path $startMenuDirectory -Force | Out-Null

        foreach ($shortcutPath in @($desktopShortcut, (Join-Path $startMenuDirectory "Nerdshell Terminal.lnk"))) {
            Backup-Item $shortcutPath $BackupRoot
            $shortcut = $shell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = $wt
            $shortcut.Arguments = "-p Nerdshell"
            $shortcut.WorkingDirectory = $HOME
            $shortcut.Description = "Abrir Nerdshell en Windows Terminal"
            $shortcut.IconLocation = "$wt,0"
            $shortcut.Save()
        }
    }

    Write-Host "  ✓ Perfil Nerdshell de Windows Terminal configurado" -ForegroundColor Green
}

Clear-Host
Write-Host "Nerdshell para Windows" -ForegroundColor Cyan
Write-Host "======================`n"

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoot = Join-Path $HOME ".config-backups\nerdshell-$stamp"
New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
$transcript = Join-Path $backupRoot "install.log"
Start-Transcript -Path $transcript -Force | Out-Null
$script:InstallExitCode = 0

try {
    Write-Step "Comprobando WinGet"
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "WinGet no está disponible. Instala 'App Installer' desde Microsoft Store y ejecuta Nerdshell de nuevo."
    }

    Write-Step "Instalando componentes principales"
    $requiredResults = @(
        (Install-WinGetPackage -Id "Microsoft.WindowsTerminal" -Name "Windows Terminal" -Required)
        (Install-WinGetPackage -Id "Microsoft.PowerShell" -Name "PowerShell 7" -Required)
        (Install-WinGetPackage -Id "Starship.Starship" -Name "Starship" -Required)
        (Install-WinGetPackage -Id "Git.Git" -Name "Git" -Required)
    )
    if ($requiredResults -contains $false) {
        throw "Uno o más componentes principales no pudieron instalarse. Revisa el registro y vuelve a intentarlo."
    }

    Write-Step "Instalando herramientas de terminal"
    $optionalPackages = @(
        @{ Id = "eza-community.eza"; Name = "eza" },
        @{ Id = "sharkdp.bat"; Name = "bat" },
        @{ Id = "BurntSushi.ripgrep.MSVC"; Name = "ripgrep" },
        @{ Id = "sharkdp.fd"; Name = "fd" },
        @{ Id = "junegunn.fzf"; Name = "fzf" },
        @{ Id = "ajeetdsouza.zoxide"; Name = "zoxide" },
        @{ Id = "Fastfetch-cli.Fastfetch"; Name = "fastfetch" },
        @{ Id = "jesseduffield.lazygit"; Name = "lazygit" },
        @{ Id = "dandavison.delta"; Name = "Git Delta" },
        @{ Id = "OpenJS.NodeJS.LTS"; Name = "Node.js LTS" },
        @{ Id = "Microsoft.OpenJDK.21"; Name = "OpenJDK 21" }
    )
    foreach ($package in $optionalPackages) {
        Install-WinGetPackage -Id $package.Id -Name $package.Name | Out-Null
    }
    Refresh-ProcessPath

    Write-Step "Instalando Nerd Font"
    try { Install-NerdFont }
    catch { Write-WarningMessage "No se pudo instalar JetBrainsMono Nerd Font: $($_.Exception.Message)" }

    Write-Step "Aplicando la configuración personal"
    Configure-PowerShellProfile $backupRoot
    Configure-GitDelta
    Configure-WindowsTerminal $backupRoot

    Write-Host "`nNerdshell se instaló correctamente." -ForegroundColor Green
    Write-Host "Abre 'Nerdshell Terminal' desde el Escritorio o el menú Inicio."
    Write-Host "Backup: $backupRoot"
} catch {
    Write-Host "`nLa instalación no pudo completarse:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "Registro: $transcript"
    $script:InstallExitCode = 1
} finally {
    Stop-Transcript | Out-Null
}

Write-Host "`nPresiona Enter para cerrar..."
[void](Read-Host)
exit $script:InstallExitCode
