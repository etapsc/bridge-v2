package customize

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

// Profile represents a personality profile loaded from profiles/*.json.
type Profile struct {
	Name        string            `json:"name"`
	Description string            `json:"description"`
	Vibes       map[string]string `json:"vibes"`
}

// LoadProfile reads a personality profile from the profiles directory.
func LoadProfile(profilesDir, name string) (*Profile, error) {
	path := filepath.Join(profilesDir, name+".json")
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("profile %q not found: %w", name, err)
	}
	var p Profile
	if err := json.Unmarshal(data, &p); err != nil {
		return nil, fmt.Errorf("invalid profile %q: %w", name, err)
	}
	return &p, nil
}

// markerStart and markerEnd delimit the personality block in agent files.
const (
	markerStart = "<!-- bridge:personality -->"
	markerEnd   = "<!-- /bridge:personality -->"
)

// markerRegex matches the entire personality block including markers.
var markerRegex = regexp.MustCompile(`(?s)` + regexp.QuoteMeta(markerStart) + `.*?` + regexp.QuoteMeta(markerEnd) + `\n?`)

// ApplyPersonality patches all agent files in a project directory with
// vibe lines from the given profile.
func ApplyPersonality(projectDir string, profile *Profile) ([]string, error) {
	var patched []string

	// Map filename keywords to profile vibe keys.
	// Keywords use stem forms to match both full names (bridge-coder.md)
	// and short names (00-code.md) across pack types.
	agentMappings := map[string]string{
		"architect":  "architect",
		"code":       "coder",
		"debug":      "debugger",
		"audit":      "auditor",
		"evaluat":    "evaluator",
		"advisor":    "advisor",
		"brainstorm": "brainstorm",
	}

	// Find all agent/command/skill files across pack types
	patterns := []string{
		".claude/agents/bridge-*.md",
		".claude/commands/bridge-*.md",
		".roo/rules-*/00-*.md",
		".roo/commands/bridge-*.md",
		".opencode/agents/bridge-*.md",
		".agents/skills/bridge-*/SKILL.md",
		".agents/procedures/bridge-*.md",
	}

	for _, pattern := range patterns {
		matches, _ := filepath.Glob(filepath.Join(projectDir, pattern))
		for _, path := range matches {
			rel, _ := filepath.Rel(projectDir, path)
			for keyword, role := range agentMappings {
				if strings.Contains(rel, keyword) {
					vibe, ok := profile.Vibes[role]
					if !ok {
						continue
					}
					if err := patchFile(path, vibe); err != nil {
						return patched, fmt.Errorf("failed to patch %s: %w", path, err)
					}
					patched = append(patched, rel)
					break // one match per file
				}
			}
		}
	}

	// Patch CLAUDE.md / AGENTS.md orchestrator personality
	for _, name := range []string{"CLAUDE.md", "AGENTS.md"} {
		path := filepath.Join(projectDir, name)
		if _, err := os.Stat(path); err == nil {
			vibe, ok := profile.Vibes["orchestrator"]
			if ok {
				if err := patchFile(path, vibe); err != nil {
					return patched, fmt.Errorf("failed to patch %s: %w", name, err)
				}
				patched = append(patched, name)
			}
		}
	}

	return patched, nil
}

// patchFile inserts or replaces the personality block in a file.
func patchFile(path, vibe string) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}

	content := string(data)
	block := fmt.Sprintf("%s\n**Personality:** %s\n%s\n", markerStart, vibe, markerEnd)

	if markerRegex.MatchString(content) {
		// Replace existing personality block
		content = markerRegex.ReplaceAllString(content, block)
	} else {
		// Insert after frontmatter (--- ... ---) or at the top
		content = insertAfterFrontmatter(content, block)
	}

	return os.WriteFile(path, []byte(content), 0644)
}

// insertAfterFrontmatter inserts text after YAML frontmatter if present,
// or after the first heading, or at the beginning.
func insertAfterFrontmatter(content, block string) string {
	lines := strings.SplitN(content, "\n", -1)

	// Look for frontmatter (--- ... ---)
	if len(lines) > 0 && strings.TrimSpace(lines[0]) == "---" {
		for i := 1; i < len(lines); i++ {
			if strings.TrimSpace(lines[i]) == "---" {
				// Insert after closing ---
				before := strings.Join(lines[:i+1], "\n")
				after := strings.Join(lines[i+1:], "\n")
				return before + "\n\n" + block + after
			}
		}
	}

	// Look for first heading
	for i, line := range lines {
		if strings.HasPrefix(line, "# ") {
			before := strings.Join(lines[:i+1], "\n")
			after := strings.Join(lines[i+1:], "\n")
			return before + "\n\n" + block + after
		}
	}

	// Prepend
	return block + "\n" + content
}

// RemovePersonality strips personality markers from all files in a project.
func RemovePersonality(projectDir string) error {
	return filepath.Walk(projectDir, func(path string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() {
			return err
		}
		if !strings.HasSuffix(path, ".md") {
			return nil
		}

		data, err := os.ReadFile(path)
		if err != nil {
			return nil // skip unreadable files
		}

		content := string(data)
		if !strings.Contains(content, markerStart) {
			return nil
		}

		cleaned := markerRegex.ReplaceAllString(content, "")
		return os.WriteFile(path, []byte(cleaned), info.Mode())
	})
}
