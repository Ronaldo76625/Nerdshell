# Nerdshell Installer for Windows

Native Windows installer that configures Windows Terminal and PowerShell 7 with
the Nerdshell profile. The executable embeds all configuration files and uses
WinGet to install supported terminal tools.

Build both Windows architectures from macOS or Linux:

```bash
./apps/windows/NerdshellInstaller/build-windows.sh 0.1.0
```

Outputs:

- `dist/windows/Nerdshell-0.1.0-Windows-x64-Setup.exe`
- `dist/windows/Nerdshell-0.1.0-Windows-ARM64-Setup.exe`

Windows 10/11 with WinGet is required. The installer is unsigned until a
Windows code-signing certificate is provided.

Verify the compiled PE files and embedded resources:

```bash
./apps/windows/NerdshellInstaller/verify-windows.sh 0.1.0
```
