package customize

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// DetectSkillDir determines the skill directory for the project's pack type.
func DetectSkillDir(projectDir string) (string, error) {
	// Claude Code: .claude/skills/
	if _, err := os.Stat(filepath.Join(projectDir, ".claude")); err == nil {
		return ".claude/skills", nil
	}
	// OpenCode: .opencode/skills/
	if _, err := os.Stat(filepath.Join(projectDir, ".opencode")); err == nil {
		return ".opencode/skills", nil
	}
	// Codex: .agents/skills/
	if _, err := os.Stat(filepath.Join(projectDir, ".agents")); err == nil {
		return ".agents/skills", nil
	}
	// RooCode Full: .roo/skills/
	if _, err := os.Stat(filepath.Join(projectDir, ".roo/skills")); err == nil {
		return ".roo/skills", nil
	}
	// RooCode Standalone: no skill directory — use .roo/skills/ anyway
	if _, err := os.Stat(filepath.Join(projectDir, ".roo")); err == nil {
		return ".roo/skills", nil
	}
	return "", fmt.Errorf("cannot detect pack type in %s", projectDir)
}

// AddSpecialization copies a specialization SKILL.md into the project's skill directory.
func AddSpecialization(projectDir, specsDir, specName string) error {
	srcPath := filepath.Join(specsDir, specName, "SKILL.md")
	if _, err := os.Stat(srcPath); err != nil {
		return fmt.Errorf("specialization %q not found in %s", specName, specsDir)
	}

	skillDir, err := DetectSkillDir(projectDir)
	if err != nil {
		return err
	}

	destDir := filepath.Join(projectDir, skillDir, fmt.Sprintf("bridge-spec-%s", specName))
	if err := os.MkdirAll(destDir, 0755); err != nil {
		return err
	}

	destPath := filepath.Join(destDir, "SKILL.md")
	data, err := os.ReadFile(srcPath)
	if err != nil {
		return err
	}

	return os.WriteFile(destPath, data, 0644)
}

// RemoveSpecialization removes a specialization from the project's skill directory.
func RemoveSpecialization(projectDir, specName string) error {
	skillDir, err := DetectSkillDir(projectDir)
	if err != nil {
		return err
	}

	specDir := filepath.Join(projectDir, skillDir, fmt.Sprintf("bridge-spec-%s", specName))
	if _, err := os.Stat(specDir); os.IsNotExist(err) {
		return fmt.Errorf("specialization %q not installed", specName)
	}

	return os.RemoveAll(specDir)
}

// ListInstalled returns the names of installed specializations.
func ListInstalled(projectDir string) ([]string, error) {
	skillDir, err := DetectSkillDir(projectDir)
	if err != nil {
		return nil, err
	}

	pattern := filepath.Join(projectDir, skillDir, "bridge-spec-*")
	matches, _ := filepath.Glob(pattern)

	var specs []string
	for _, m := range matches {
		base := filepath.Base(m)
		name := strings.TrimPrefix(base, "bridge-spec-")
		specs = append(specs, name)
	}
	return specs, nil
}
