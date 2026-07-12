# Nerdshell PowerShell profile

$env:STARSHIP_CONFIG = Join-Path $HOME ".config\starship.toml"
$env:EZA_CONFIG_DIR = Join-Path $HOME ".config\eza"
$env:BAT_PAGER = "less -FR"

try {
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -HistoryNoDuplicates
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
} catch {
    # Older PSReadLine versions keep their defaults.
}

if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression ((&zoxide init powershell) -join "`n")
}

Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
Remove-Item Alias:gc -Force -ErrorAction SilentlyContinue

function global:ls {
    if (Get-Command eza -ErrorAction SilentlyContinue) {
        & eza --icons=always --color=always --group-directories-first @args
    } else {
        Get-ChildItem @args
    }
}

function global:l { ls @args }
function global:ll {
    if (Get-Command eza -ErrorAction SilentlyContinue) {
        & eza -lh --icons=always --color=always --group-directories-first --git @args
    } else {
        Get-ChildItem @args | Format-Table
    }
}
function global:la {
    if (Get-Command eza -ErrorAction SilentlyContinue) {
        & eza -lah --icons=always --color=always --group-directories-first --git @args
    } else {
        Get-ChildItem -Force @args | Format-Table
    }
}
function global:lt {
    if (Get-Command eza -ErrorAction SilentlyContinue) {
        & eza --tree --level=2 --icons=always --color=always --group-directories-first @args
    } else {
        tree @args
    }
}

function global:search {
    if (Get-Command rg -ErrorAction SilentlyContinue) { & rg @args }
    else { Get-ChildItem -Recurse | Select-String @args }
}
function global:ffind {
    if (Get-Command fd -ErrorAction SilentlyContinue) { & fd --glob @args }
    else { Get-ChildItem -Recurse -Filter $args[0] }
}
function global:preview {
    if (Get-Command bat -ErrorAction SilentlyContinue) { & bat --style=numbers,changes --color=always @args }
    else { Get-Content @args }
}

function global:home { Set-Location $HOME }
function global:downloads { Set-Location (Join-Path $HOME "Downloads") }
function global:desktop { Set-Location ([Environment]::GetFolderPath("Desktop")) }
function global:documents { Set-Location ([Environment]::GetFolderPath("MyDocuments")) }
function global:reload { . $PROFILE }
function global:cls { Clear-Host }
function global:serve { python -m http.server @args }

function global:gs { git status --short --branch @args }
function global:gst { git status @args }
function global:ga { git add @args }
function global:gaa { git add --all @args }
function global:gc { git commit @args }
function global:gcm { git commit -m @args }
function global:gp { git push @args }
function global:gl { git pull @args }
function global:gco { git checkout @args }
function global:gb { git branch @args }
function global:gd { git diff @args }
function global:gds { git diff --staged @args }
function global:glog { git log --oneline --graph --decorate --all @args }
function global:lg { lazygit @args }

function global:java-version { java -version }
function global:node-version { node --version }
function global:ff { fastfetch @args }

$env:NERDSHELL = "1"
