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

func addCmd() *cobra.Command {
	var name, packName, personality, target, repo, version string
	var specs []string

	cmd := &cobra.Command{
		Use:   "add",
		Short: "Add BRIDGE tooling to an existing project",
		Long:  "Install BRIDGE methodology pack into an existing project directory without overwriting protected files.",
		RunE: func(cmd *cobra.Command, args []string) error {
			if name == "" {
				return fmt.Errorf("--name is required")
			}
			if packName == "" {
				return fmt.Errorf("--pack is required")
			}
			if !isValidPack(packName) {
				return fmt.Errorf("invalid pack %q: must be one of %v", packName, config.Packs())
			}
			if !isValidPersonality(personality) {
				return fmt.Errorf("invalid personality %q: must be one of %v", personality, config.Personalities())
			}

			// Resolve target to absolute path
			absTarget, err := filepath.Abs(target)
			if err != nil {
				return fmt.Errorf("invalid target: %w", err)
			}

			if _, err := os.Stat(absTarget); os.IsNotExist(err) {
				return fmt.Errorf("target directory does not exist: %s", absTarget)
			}

			// Resolve source
			execDir := executableDir()
			src := pack.Resolve(execDir, packName, repo, version)

			fmt.Printf("Adding BRIDGE v3 to existing project...\n")
			fmt.Printf("  Project:   %s\n", name)
			fmt.Printf("  Pack:      %s\n", packName)
			fmt.Printf("  Target:    %s\n", absTarget)
			fmt.Printf("  Source:    %s\n", src.Mode)
			fmt.Println()

			// Extract to staging directory
			stagingDir, err := os.MkdirTemp("", "bridge-staging-*")
			if err != nil {
				return fmt.Errorf("failed to create staging dir: %w", err)
			}
			defer os.RemoveAll(stagingDir)

			fmt.Println("Extracting pack...")
			if err := pack.Extract(src, stagingDir); err != nil {
				return fmt.Errorf("failed to extract pack: %w", err)
			}

			// Replace placeholders in staging
			fmt.Println("Personalizing files...")
			if err := pack.ReplacePlaceholders(stagingDir, name); err != nil {
				return fmt.Errorf("failed to replace placeholders: %w", err)
			}

			// Install with protection
			fmt.Println("Installing framework files...")
			result, err := pack.InstallToExisting(stagingDir, absTarget)
			if err != nil {
				return fmt.Errorf("failed to install: %w", err)
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
				patched, err := customize.ApplyPersonality(absTarget, profile)
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
					if err := customize.AddSpecialization(absTarget, specsDir, spec); err != nil {
						return fmt.Errorf("failed to add spec %q: %w", spec, err)
					}
					fmt.Printf("  + Added specialization: %s\n", spec)
				}
			}

			// Save .bridge.json
			cfg := &config.BridgeConfig{
				Version:         "3.0",
				Pack:            packName,
				Personality:     personality,
				Specializations: specs,
			}
			if err := cfg.Save(absTarget); err != nil {
				return fmt.Errorf("failed to save config: %w", err)
			}

			// Print report
			fmt.Printf("\nBRIDGE v3 added to: %s\n\n", absTarget)
			if len(result.Installed) > 0 {
				fmt.Printf("Installed (%d files):\n", len(result.Installed))
				for _, f := range result.Installed {
					fmt.Printf("  + %s\n", f)
				}
			}
			if len(result.Skipped) > 0 {
				fmt.Printf("\nSkipped (%d items):\n", len(result.Skipped))
				for _, f := range result.Skipped {
					fmt.Printf("  ~ %s\n", f)
				}
			}
			fmt.Println()
			printNextSteps(packName, absTarget)

			return nil
		},
	}

	cmd.Flags().StringVarP(&name, "name", "n", "", "Project name")
	cmd.Flags().StringVarP(&packName, "pack", "p", "", "Pack: full, standalone, claude-code, codex, opencode, dual-agent")
	cmd.Flags().StringVar(&personality, "personality", "balanced", "Personality: strict, balanced, mentoring")
	cmd.Flags().StringSliceVar(&specs, "spec", nil, "Domain specializations")
	cmd.Flags().StringVarP(&target, "target", "t", ".", "Target project directory")
	cmd.Flags().StringVarP(&repo, "repo", "r", "etapsc/bridge", "GitHub repo for remote download")
	cmd.Flags().StringVarP(&version, "version", "v", "latest", "Release tag for remote download")

	return cmd
}
