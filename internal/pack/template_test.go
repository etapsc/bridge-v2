package pack

import (
	"os"
	"path/filepath"
	"testing"
)

func TestSlugify(t *testing.T) {
	tests := []struct {
		input    string
		expected string
	}{
		{"My Project", "my-project"},
		{"Hello World App", "hello-world-app"},
		{"simple", "simple"},
		{"UPPERCASE", "uppercase"},
		{"  spaces  ", "spaces"},
		{"special!@#chars", "special-chars"},
		{"multiple---dashes", "multiple-dashes"},
	}

	for _, tt := range tests {
		result := Slugify(tt.input)
		if result != tt.expected {
			t.Errorf("Slugify(%q) = %q, want %q", tt.input, result, tt.expected)
		}
	}
}

func TestReplacePlaceholders(t *testing.T) {
	dir := t.TempDir()

	// Create test files
	mdFile := filepath.Join(dir, "README.md")
	os.WriteFile(mdFile, []byte("# {{PROJECT_NAME}}\nWelcome to {{PROJECT_NAME}}"), 0644)

	jsonFile := filepath.Join(dir, "config.json")
	os.WriteFile(jsonFile, []byte(`{"name": "{{PROJECT_NAME}}"}`), 0644)

	goFile := filepath.Join(dir, "main.go")
	os.WriteFile(goFile, []byte("// {{PROJECT_NAME}} should not be replaced"), 0644)

	err := ReplacePlaceholders(dir, "Test Project")
	if err != nil {
		t.Fatalf("ReplacePlaceholders failed: %v", err)
	}

	// Check .md file was replaced
	data, _ := os.ReadFile(mdFile)
	if string(data) != "# Test Project\nWelcome to Test Project" {
		t.Errorf("md file not replaced correctly: %s", data)
	}

	// Check .json file was replaced
	data, _ = os.ReadFile(jsonFile)
	if string(data) != `{"name": "Test Project"}` {
		t.Errorf("json file not replaced correctly: %s", data)
	}

	// Check .go file was NOT replaced
	data, _ = os.ReadFile(goFile)
	if string(data) != "// {{PROJECT_NAME}} should not be replaced" {
		t.Errorf("go file should not be modified: %s", data)
	}
}
