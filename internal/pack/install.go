package pack

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// InstallResult tracks what happened during installation.
type InstallResult struct {
	Installed []string
	Skipped   []string
}

// protectedDirs are top-level directories whose existing files are never overwritten.
var protectedDirs = map[string]bool{
	"docs": true, "doc": true,
	"src": true, "tests": true, "test": true,
}

// InstallToExisting copies pack files from stagingDir into targetDir,
// skipping existing files in protected directories.
func InstallToExisting(stagingDir, targetDir string) (*InstallResult, error) {
	result := &InstallResult{}

	err := filepath.Walk(stagingDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			return nil
		}

		rel, err := filepath.Rel(stagingDir, path)
		if err != nil {
			return err
		}

		destPath := filepath.Join(targetDir, rel)

		// Check if file is in a protected directory
		topDir := strings.SplitN(rel, string(os.PathSeparator), 2)[0]
		if protectedDirs[topDir] {
			if _, err := os.Stat(destPath); err == nil {
				result.Skipped = append(result.Skipped, fmt.Sprintf("%s (exists)", rel))
				return nil
			}
		}

		// Install the file
		if err := os.MkdirAll(filepath.Dir(destPath), 0755); err != nil {
			return err
		}
		if err := copyFile(path, destPath, info.Mode()); err != nil {
			return err
		}
		result.Installed = append(result.Installed, rel)
		return nil
	})

	return result, err
}
