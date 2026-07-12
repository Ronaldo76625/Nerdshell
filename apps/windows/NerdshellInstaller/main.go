package main

import (
	"embed"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"syscall"
	"unsafe"
)

var version = "0.1.0"

//go:embed resources/*
var resources embed.FS

var (
	user32        = syscall.NewLazyDLL("user32.dll")
	shell32       = syscall.NewLazyDLL("shell32.dll")
	messageBoxW   = user32.NewProc("MessageBoxW")
	shellExecuteW = shell32.NewProc("ShellExecuteW")
)

const (
	mbOK              = 0x00000000
	mbYesNo           = 0x00000004
	mbIconInformation = 0x00000040
	mbIconError       = 0x00000010
	idYes             = 6
	swShowNormal      = 1
)

func utf16(value string) *uint16 {
	result, err := syscall.UTF16PtrFromString(value)
	if err != nil {
		return nil
	}
	return result
}

func messageBox(title, message string, flags uintptr) int {
	result, _, _ := messageBoxW.Call(
		0,
		uintptr(unsafe.Pointer(utf16(message))),
		uintptr(unsafe.Pointer(utf16(title))),
		flags,
	)
	return int(result)
}

func extractResources() (string, error) {
	destination := filepath.Join(os.TempDir(), "NerdshellInstaller", version)
	if err := os.RemoveAll(destination); err != nil {
		return "", err
	}
	if err := os.MkdirAll(destination, 0o755); err != nil {
		return "", err
	}

	err := fs.WalkDir(resources, "resources", func(path string, entry fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if entry.IsDir() {
			return nil
		}

		data, err := resources.ReadFile(path)
		if err != nil {
			return err
		}
		target := filepath.Join(destination, filepath.Base(path))
		return os.WriteFile(target, data, 0o644)
	})
	return destination, err
}

func launchElevatedInstaller(resourceRoot string) error {
	script := filepath.Join(resourceRoot, "install.ps1")
	parameters := fmt.Sprintf(
		`-NoLogo -NoProfile -ExecutionPolicy Bypass -File "%s" -ResourceRoot "%s"`,
		script,
		resourceRoot,
	)

	result, _, callErr := shellExecuteW.Call(
		0,
		uintptr(unsafe.Pointer(utf16("runas"))),
		uintptr(unsafe.Pointer(utf16("powershell.exe"))),
		uintptr(unsafe.Pointer(utf16(parameters))),
		0,
		swShowNormal,
	)
	if result <= 32 {
		return fmt.Errorf("Windows no pudo iniciar el instalador (código %d): %v", result, callErr)
	}
	return nil
}

func main() {
	choice := messageBox(
		"Nerdshell Installer",
		"Nerdshell configurará Windows Terminal, PowerShell 7, Starship, Nerd Font y herramientas para desarrollo.\n\nSe crearán copias de seguridad antes de modificar tu perfil.\n\n¿Deseas continuar?",
		mbYesNo|mbIconInformation,
	)
	if choice != idYes {
		return
	}

	resourceRoot, err := extractResources()
	if err != nil {
		messageBox("Nerdshell Installer", "No se pudieron preparar los archivos de instalación:\n"+err.Error(), mbOK|mbIconError)
		return
	}
	if err := launchElevatedInstaller(resourceRoot); err != nil {
		messageBox("Nerdshell Installer", err.Error(), mbOK|mbIconError)
		return
	}

	messageBox(
		"Nerdshell Installer",
		"La instalación se abrió en PowerShell. Sigue el progreso en esa ventana. Puedes cerrar este mensaje.",
		mbOK|mbIconInformation,
	)
}
