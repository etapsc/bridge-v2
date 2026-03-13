package customize

import (
	"os"
	"path/filepath"
	"testing"
)

func TestAddAndRemoveSpecialization(t *testing.T) {
	// Setup: create a project dir with .claude/skills/
	projectDir := t.TempDir()
	os.MkdirAll(filepath.Join(projectDir, ".claude", "skills"), 0755)

	// Setup: create a specialization source
	specsDir := t.TempDir()
	specSrc := filepath.Join(specsDir, "frontend")
	os.MkdirAll(specSrc, 0755)
	os.WriteFile(filepath.Join(specSrc, "SKILL.md"), []byte("---\nname: Frontend\n---\n# Frontend"), 0644)

	// Add
	err := AddSpecialization(projectDir, specsDir, "frontend")
	if err != nil {
		t.Fatalf("AddSpecialization failed: %v", err)
	}

	// Verify installed
	installed, _ := ListInstalled(projectDir)
	if len(installed) != 1 || installed[0] != "frontend" {
		t.Errorf("expected [frontend], got %v", installed)
	}

	// Verify file exists
	dest := filepath.Join(projectDir, ".claude", "skills", "bridge-spec-frontend", "SKILL.md")
	if _, err := os.Stat(dest); err != nil {
		t.Errorf("SKILL.md not found at %s", dest)
	}

	// Remove
	err = RemoveSpecialization(projectDir, "frontend")
	if err != nil {
		t.Fatalf("RemoveSpecialization failed: %v", err)
	}

	installed, _ = ListInstalled(projectDir)
	if len(installed) != 0 {
		t.Errorf("expected empty, got %v", installed)
	}
}

func TestDetectSkillDir(t *testing.T) {
	tests := []struct {
		dirs     []string
		expected string
	}{
		{[]string{".claude"}, ".claude/skills"},
		{[]string{".opencode"}, ".opencode/skills"},
		{[]string{".agents"}, ".agents/skills"},
		{[]string{".roo/skills"}, ".roo/skills"},
	}

	for _, tt := range tests {
		dir := t.TempDir()
		for _, d := range tt.dirs {
			os.MkdirAll(filepath.Join(dir, d), 0755)
		}
		result, err := DetectSkillDir(dir)
		if err != nil {
			t.Errorf("DetectSkillDir failed for %v: %v", tt.dirs, err)
			continue
		}
		if result != tt.expected {
			t.Errorf("DetectSkillDir(%v) = %s, want %s", tt.dirs, result, tt.expected)
		}
	}
}
