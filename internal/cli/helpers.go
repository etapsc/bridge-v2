package cli

import (
	"fmt"
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

// resolveDataDir finds a data subdirectory (profiles/, specializations/) by
// searching multiple locations. This allows the binary to work regardless of
// where it is installed.
func resolveDataDir(subdir string) (string, error) {
	candidates := []string{}

	// 1. Next to executable
	candidates = append(candidates, filepath.Join(executableDir(), subdir))

	// 2. BRIDGE_DATA_DIR env var
	if env := os.Getenv("BRIDGE_DATA_DIR"); env != "" {
		candidates = append(candidates, filepath.Join(env, subdir))
	}

	// 3. ~/.bridge/data/
	if home, err := os.UserHomeDir(); err == nil {
		candidates = append(candidates, filepath.Join(home, ".bridge", "data", subdir))
	}

	// 4. Current working directory (development mode)
	if cwd, err := os.Getwd(); err == nil {
		candidates = append(candidates, filepath.Join(cwd, subdir))
	}

	for _, dir := range candidates {
		if info, err := os.Stat(dir); err == nil && info.IsDir() {
			return dir, nil
		}
	}

	return "", fmt.Errorf("%s directory not found (checked: executable dir, $BRIDGE_DATA_DIR, ~/.bridge/data/, cwd)", subdir)
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
