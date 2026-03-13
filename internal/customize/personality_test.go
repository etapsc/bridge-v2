package customize

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestPatchFileInsert(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "agent.md")
	content := "---\nname: test\n---\n\nYou are an agent.\n\n## Rules\n- Do stuff\n"
	os.WriteFile(path, []byte(content), 0644)

	err := patchFile(path, "Be skeptical and thorough.")
	if err != nil {
		t.Fatalf("patchFile failed: %v", err)
	}

	data, _ := os.ReadFile(path)
	result := string(data)

	if !strings.Contains(result, markerStart) {
		t.Error("missing personality marker start")
	}
	if !strings.Contains(result, "Be skeptical and thorough.") {
		t.Error("missing vibe text")
	}
	if !strings.Contains(result, markerEnd) {
		t.Error("missing personality marker end")
	}
	if !strings.Contains(result, "## Rules") {
		t.Error("original content should be preserved")
	}
}

func TestPatchFileReplace(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "agent.md")
	content := "---\nname: test\n---\n\n" + markerStart + "\n**Personality:** Old vibe.\n" + markerEnd + "\n\nYou are an agent.\n"
	os.WriteFile(path, []byte(content), 0644)

	err := patchFile(path, "New vibe.")
	if err != nil {
		t.Fatalf("patchFile failed: %v", err)
	}

	data, _ := os.ReadFile(path)
	result := string(data)

	if strings.Contains(result, "Old vibe") {
		t.Error("old vibe should be replaced")
	}
	if !strings.Contains(result, "New vibe.") {
		t.Error("new vibe should be present")
	}
	// Should have exactly one pair of markers
	if strings.Count(result, markerStart) != 1 {
		t.Errorf("expected 1 marker start, got %d", strings.Count(result, markerStart))
	}
}

func TestLoadProfile(t *testing.T) {
	dir := t.TempDir()
	profileJSON := `{"name":"test","description":"A test profile","vibes":{"architect":"Be minimal.","coder":"Write tests."}}`
	os.WriteFile(filepath.Join(dir, "test.json"), []byte(profileJSON), 0644)

	p, err := LoadProfile(dir, "test")
	if err != nil {
		t.Fatalf("LoadProfile failed: %v", err)
	}
	if p.Name != "test" {
		t.Errorf("expected name test, got %s", p.Name)
	}
	if p.Vibes["architect"] != "Be minimal." {
		t.Errorf("expected architect vibe, got %s", p.Vibes["architect"])
	}
}
