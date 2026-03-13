package pack

import (
	"os"
	"path/filepath"
	"strings"
)

// templateExtensions are file types that may contain the {{PROJECT_NAME}} placeholder.
var templateExtensions = map[string]bool{
	".md":       true,
	".json":     true,
	".toml":     true,
	".roomodes": true,
}

// ReplacePlaceholders walks destDir and replaces {{PROJECT_NAME}} with the given name
// in all supported file types.
func ReplacePlaceholders(destDir, projectName string) error {
	return filepath.Walk(destDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			return nil
		}

		ext := filepath.Ext(path)
		base := filepath.Base(path)

		// Check extension or special filename
		if !templateExtensions[ext] && base != ".roomodes" {
			return nil
		}

		data, err := os.ReadFile(path)
		if err != nil {
			return err
		}

		content := string(data)
		if !strings.Contains(content, "{{PROJECT_NAME}}") {
			return nil
		}

		replaced := strings.ReplaceAll(content, "{{PROJECT_NAME}}", projectName)
		return os.WriteFile(path, []byte(replaced), info.Mode())
	})
}

// Slugify converts a project name to a URL/directory-safe slug.
func Slugify(name string) string {
	s := strings.ToLower(name)
	var result []byte
	for _, c := range []byte(s) {
		if (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') {
			result = append(result, c)
		} else {
			if len(result) > 0 && result[len(result)-1] != '-' {
				result = append(result, '-')
			}
		}
	}
	// Trim leading/trailing dashes
	return strings.Trim(string(result), "-")
}
