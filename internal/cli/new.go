package cli

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/etapsc/bridge/internal/config"
	"github.com/etapsc/bridge/internal/customize"
	"github.com/etapsc/bridge/internal/pack"
	"github.com/spf13/cobra"
)

func newCmd() *cobra.Command {
	var name, packName, personality, output, repo, version string
	var specs []string

	cmd := &cobra.Command{
		Use:   "new",
		Short: "Create a new project with BRIDGE tooling",
		Long:  "Create a new project directory with BRIDGE methodology pack, personality, and domain specializations.",
		RunE: func(cmd *cobra.Command, args []string) error {
			if name == "" {
				return fmt.Errorf("--name is required")
			}
			if packName == "" {
				return fmt.Errorf("--pack is required (full, standalone, claude-code, codex, opencode)")
			}
			if !isValidPack(packName) {
				return fmt.Errorf("invalid pack %q: must be one of %v", packName, config.Packs())
			}
			if !isValidPersonality(personality) {
				return fmt.Errorf("invalid personality %q: must be one of %v", personality, config.Personalities())
			}

			slug := pack.Slugify(name)
			projectDir := filepath.Join(output, slug)

			// Check if target exists
			if info, err := os.Stat(projectDir); err == nil && info.IsDir() {
				return fmt.Errorf("directory already exists: %s", projectDir)
			}

			// Resolve source
			execDir := executableDir()
			src := pack.Resolve(execDir, packName, repo, version)

			fmt.Printf("Setting up BRIDGE v3...\n")
			fmt.Printf("  Project:   %s\n", name)
			fmt.Printf("  Slug:      %s\n", slug)
			fmt.Printf("  Pack:      %s\n", packName)
			fmt.Printf("  Directory: %s\n", projectDir)
			fmt.Printf("  Source:    %s\n", src.Mode)
			if personality != "balanced" {
				fmt.Printf("  Personality: %s\n", personality)
			}
			if len(specs) > 0 {
				fmt.Printf("  Specs:     %v\n", specs)
			}
			fmt.Println()

			// Create project directory
			if err := os.MkdirAll(projectDir, 0755); err != nil {
				return fmt.Errorf("failed to create directory: %w", err)
			}

			// Extract pack
			fmt.Println("Extracting pack...")
			if err := pack.Extract(src, projectDir); err != nil {
				return fmt.Errorf("failed to extract pack: %w", err)
			}

			// Replace placeholders
			fmt.Println("Personalizing files...")
			if err := pack.ReplacePlaceholders(projectDir, name); err != nil {
				return fmt.Errorf("failed to replace placeholders: %w", err)
			}

			// Apply personality
			if personality != "balanced" {
				profilesDir, err := resolveDataDir("profiles")
				if err != nil {
					return fmt.Errorf("cannot find personality profiles: %w", err)
				}
				profile, err := customize.LoadProfile(profilesDir, personality)
				if err != nil {
					return err
				}
				patched, err := customize.ApplyPersonality(projectDir, profile)
				if err != nil {
					return fmt.Errorf("failed to apply personality: %w", err)
				}
				if len(patched) > 0 {
					fmt.Printf("Applied %q personality to %d files\n", personality, len(patched))
				}
			}

			// Install specializations
			if len(specs) > 0 {
				specsDir, err := resolveDataDir("specializations")
				if err != nil {
					return fmt.Errorf("cannot find specializations: %w", err)
				}
				for _, spec := range specs {
					if err := customize.AddSpecialization(projectDir, specsDir, spec); err != nil {
						return fmt.Errorf("failed to add spec %q: %w", spec, err)
					}
					fmt.Printf("  + Added specialization: %s\n", spec)
				}
			}

			// Create standard directories
			for _, dir := range []string{
				"docs/contracts",
				"tests/unit",
				"tests/integration",
				"tests/e2e",
				"src",
			} {
				os.MkdirAll(filepath.Join(projectDir, dir), 0755)
			}

			// Save .bridge.json
			cfg := &config.BridgeConfig{
				Version:         "3.0",
				Pack:            packName,
				Personality:     personality,
				Specializations: specs,
			}
			if err := cfg.Save(projectDir); err != nil {
				return fmt.Errorf("failed to save config: %w", err)
			}

			// Print summary
			fmt.Printf("\nBRIDGE v3 project created: %s\n\n", projectDir)
			printNextSteps(packName, projectDir)

			return nil
		},
	}

	cmd.Flags().StringVarP(&name, "name", "n", "", "Project name")
	cmd.Flags().StringVarP(&packName, "pack", "p", "", "Pack: full, standalone, claude-code, codex, opencode")
	cmd.Flags().StringVar(&personality, "personality", "balanced", "Personality: strict, balanced, mentoring")
	cmd.Flags().StringSliceVar(&specs, "spec", nil, "Domain specializations: frontend, backend, api, data, infra, mobile, security")
	cmd.Flags().StringVarP(&output, "output", "o", ".", "Output parent directory")
	cmd.Flags().StringVarP(&repo, "repo", "r", "etapsc/bridge", "GitHub repo for remote download")
	cmd.Flags().StringVarP(&version, "version", "v", "latest", "Release tag for remote download")

	return cmd
}

func printNextSteps(packName, projectDir string) {
	fmt.Printf("Next steps:\n")
	fmt.Printf("  1. cd %s\n", projectDir)
	switch packName {
	case "claude-code":
		fmt.Println("  2. Run: claude")
		fmt.Println("  3. Run /bridge-brainstorm or /bridge-requirements-only to start")
	case "codex":
		fmt.Println("  2. Run: codex")
		fmt.Println("  3. Invoke $bridge-brainstorm or $bridge-requirements-only to start")
	case "opencode":
		fmt.Println("  2. Run: opencode")
		fmt.Println("  3. Run /bridge-brainstorm or /bridge-requirements-only to start")
	default:
		fmt.Println("  2. Open in VS Code with RooCode extension")
		fmt.Println("  3. Run /bridge-brainstorm or /bridge-requirements-only to start")
	}
	fmt.Println()
}
