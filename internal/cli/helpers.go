package cli

import (
	"os"
	"path/filepath"

	"github.com/etapsc/bridge/internal/config"
)

// executableDir returns the directory containing the bridge binary,
// or the current working directory if it can't be determined.
// This is used to find local pack folders/archives.
func executableDir() string {
	exe, err := os.Executable()
	if err != nil {
		cwd, _ := os.Getwd()
		return cwd
	}
	resolved, err := filepath.EvalSymlinks(exe)
	if err != nil {
		return filepath.Dir(exe)
	}
	return filepath.Dir(resolved)
}

func isValidPack(p string) bool {
	for _, valid := range config.Packs() {
		if p == valid {
			return true
		}
	}
	return false
}

func isValidPersonality(p string) bool {
	for _, valid := range config.Personalities() {
		if p == valid {
			return true
		}
	}
	return false
}
